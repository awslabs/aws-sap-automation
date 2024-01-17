#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Applies a list of custom tags onto all related resources of a given Lauch Wizard for SAP deployment.
#TYPE: AWS Launch Wizard for SAP - PostConfiguration script
#TARGET: SAP ASCS/PAS
#EXECUTE: Can be executed on any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: cspruell@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/lw_bootstrap.sh"

TAGS=$(aws ssm get-parameter --name "sap-custom-tags" --query 'Parameter.Value' --output text)
echo "Tags defined..."
echo $TAGS

if [[ $TAGS = "" ]]
then
echo "Custom tags not found or empty. Please check the Systems Manager - Parameter Store 'sap-custom-tags'!"
exit 1
else
echo "Start tagging the following resources..."

#Using the EC2 Instance ID, locate the Launch Wizard ID
LAUNCHWIZID=`aws ec2 describe-tags --filters "Name=resource-id,Values=$EC2_INSTANCE_ID" "Name=key,Values=LaunchWizardResourceGroupID" --output=text | cut -f5`

#Using the Launch Wizard ID, returns the ARNs of all resources that have that ID as a tag
RESOURCE_GROUP_ARN_LIST1=$(aws resource-groups search-resources --resource-query '{"Type":"TAG_FILTERS_1_0", "Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"LaunchWizardResourceGroupID\",\"Values\":[\"'$LAUNCHWIZID'\"]}]}"}' --query 'ResourceIdentifiers[].ResourceArn' --output text)

RESOURCE_GROUP_ARN_LIST1_CLEAN=""
COUNT=0
for word in $RESOURCE_GROUP_ARN_LIST1
do
    #Ignore CloudFormationARN & 'None' resource(s)
    if [[ ${word} != *"arn:aws:cloudformation"* ]] && [[ ${word} != "None" ]]; then
    echo $COUNT $word
    RESOURCE_GROUP_ARN_LIST1_CLEAN=$(echo "$RESOURCE_GROUP_ARN_LIST1_CLEAN" "$word")
    COUNT=$((COUNT+1))
    fi

    if [[ $COUNT == 20 ]]; then 
    #Tags all resources in the ARN list with all the tags specified, supports only 20 resources at a time
    OUTPUT=$(aws resourcegroupstaggingapi tag-resources --resource-arn-list $RESOURCE_GROUP_ARN_LIST1_CLEAN --tags $TAGS)
    RESOURCE_GROUP_ARN_LIST1_CLEAN=""
    fi

done

if [[ $RESOURCE_GROUP_ARN_LIST1_CLEAN != "" ]]; then 
#Tags all resources in the ARN list with all the tags specified, supports only 20 resources at a time
OUTPUT=$(aws resourcegroupstaggingapi tag-resources --resource-arn-list $RESOURCE_GROUP_ARN_LIST1_CLEAN --tags $TAGS)
fi

echo "All done!"

fi