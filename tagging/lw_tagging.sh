#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Applies a list of custom tags onto all related resources of a given Lauch Wizard for SAP deployment.
#TYPE: AWS Launch Wizard for SAP - PostConfiguration script
#EXECUTE: Can be executed on any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: cspruell@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/lw_bootstrap.sh"

TAGS=$(aws ssm get-parameter --name "sap-custom-tags" --query 'Parameter.Value' --output text)
echo $TAGS

if [[ $TAGS = "" ]]
then
echo "Custom tags not found or empty. Please check the Systems Manager - Parameter Store 'sap-custom-tags'!"
exit 1
else
echo "Start tagging..."

#Using the EC2 Instance ID, locate the Launch Wizard ID
LAUNCHWIZID=`aws ec2 describe-tags --filters "Name=resource-id,Values=$EC2_INSTANCE_ID" "Name=key,Values=LaunchWizardResourceGroupID" --output=text | cut -f5`

#Using the Launch Wizard ID, returns the ARNs of all resources that have that ID as a tag
RESOURCE_GROUP_ARN_LIST1=$(aws resource-groups search-resources --max-items 20 --resource-query '{"Type":"TAG_FILTERS_1_0", "Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"LaunchWizardResourceGroupID\",\"Values\":[\"'$LAUNCHWIZID'\"]}]}"}' --query 'ResourceIdentifiers[].ResourceArn' --output text)

#Remove CloudFormationARN & 'None' resources
RESOURCE_GROUP_ARN_LIST1_CLEAN=""
for word in $RESOURCE_GROUP_ARN_LIST1
do
    echo $word
    if [[ ${word} != *"arn:aws:cloudformation"* ]] && [[ ${word} != "None" ]]; then
    RESOURCE_GROUP_ARN_LIST1_CLEAN=$(echo "$RESOURCE_GROUP_ARN_LIST1_CLEAN" "$word")
    fi
done

#Tags all resources in the ARN list with all the tags specified, supports only 20 resources at a time
aws resourcegroupstaggingapi tag-resources --resource-arn-list $RESOURCE_GROUP_ARN_LIST1_CLEAN --tags $TAGS

NEXTTOKEN=$(aws resource-groups search-resources --max-items 20 --resource-query '{"Type":"TAG_FILTERS_1_0", "Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"LaunchWizardResourceGroupID\",\"Values\":[\"'$LAUNCHWIZID'\"]}]}"}' --query 'NextToken')
if [[ $NEXTTOKEN == "" ]]; 
then
echo "All done!"
else
RESOURCE_GROUP_ARN_LIST2=$(aws resource-groups search-resources --starting-token $NEXTTOKEN --resource-query '{"Type":"TAG_FILTERS_1_0", "Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"LaunchWizardResourceGroupID\",\"Values\":[\"'$LAUNCHWIZID'\"]}]}"}' --query 'ResourceIdentifiers[].ResourceArn' --output text)
aws resourcegroupstaggingapi tag-resources --resource-arn-list $RESOURCE_GROUP_ARN_LIST2 --tags $TAGS
echo "All done!"
fi

fi