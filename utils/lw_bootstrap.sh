#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Helper script to extract AWS Launch Wizard for SAP deployment configuration
#EXECUTE: Can be run from any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: mtoerpe@, meyro@

#set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/colors.sh"

echo ""
echo "---------------------------------------------------"
echo "LW Bootstrap Script"
echo "---------------------------------------------------"
echo ""

echo -n "Fetch CloudFormation Stack config"
echo ""

#Determine IMDSv1 or IMDSv2
METADATA_RESPONSE=$(curl --write-out '%{http_code}' --silent --output /dev/null http://169.254.169.254/latest/meta-data/)
HEADER=""
if [ $METADATA_RESPONSE -ne 200 ]; then
echo -n "Use IMDSv2!"
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
HEADER="X-aws-ec2-metadata-token: $TOKEN"
fi

EC2_INSTANCE_ID=$(curl --header "$HEADER" --silent http://169.254.169.254/latest/meta-data/instance-id)
if [ $? -ne 0 ]; then
echo -e "${RED}Error:${NO_COLOR} Could not determine EC2 Instance ID"
exit 1;
fi
StackName=$(aws cloudformation describe-stack-resources --physical-resource-id $EC2_INSTANCE_ID --query "StackResources[0].StackName")
StackName=$(sed -e 's/^"//' -e 's/"$//' <<<"$StackName")
StackNotificationARNs=$(aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].NotificationARNs")   
#StackNotificationARNs=$(sed -e 's/\[//g' -e 's/\]//g' -e 's/ //g' -e 's/^"//' -e 's/"$//' <<<"$StackNotificationARNs")       # todo: Transform into a format usable when more than one topics are present
StackId=$(aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].StackId")
StackId=$(sed -e 's/^"//' -e 's/"$//' <<<"$StackId")

echo -e " ${GREEN}...done!${NO_COLOR}"

echo -n "Fetch network config"

interface=$(curl --header "$HEADER" --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
VPC_ID=$(curl --header "$HEADER" --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${interface}/vpc-id)
SUBNET_ID=$(curl --header "$HEADER" --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${interface}/subnet-id)
mac=$(curl --header "$HEADER" --silent http://169.254.169.254/latest/meta-data/mac)
SECURITYGROUP=$(curl --header "$HEADER" --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}/security-group-ids)
CURRENT_HOSTNAME=$(hostname)

echo -e " ${GREEN}...done!${NO_COLOR}"

echo -n "Fetch SAP system config"
json=$(aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[*].Parameters')
json=$(sed 's/\[//g' <<< $json)
json=$(sed 's/\]//g' <<< $json)
json=$(sed 's/\\//g' <<< $json)
json=$(sed 's/ //g' <<< $json)
json=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' <<< $json)
echo "$json" > "parameters.json"

SAP_SID=$(sed -n 's|.*"ParameterKey":"SAPSID", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
SAP_HANA_INSTANCE_NR=$(sed -n 's|.*"ParameterKey":"SAPInstanceNum", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
SAP_CI_INSTANCE_NR=$(sed -n 's|.*"CI_INSTANCE_NR":"\([^"]*\)".*|\1|p' parameters.json)
pasparam=$(sed -n 's|.*"ParameterKey":"PASParameterList", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
SAP_CI_HOSTNAME=$(cut -d',' -f3 <<<$pasparam)
SAP_PRODUCT_ID=$(sed -n 's|.*"PRODUCT_ID":"\([^"]*\)".*|\1|p' parameters.json)
SAP_HANA_SID=$(sed -n 's|.*"ParameterKey":"HANASID", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
SAP_HANA_HOSTNAME=$(sed -n 's|.*"ParameterKey":"HANAHostname", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
LW_DEPLOYMENT_SCENARIO=$(sed -n 's|.*"ParameterKey":"deploymentScenario", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
LW_DEPLOYMENT_NAME=$(sed -n 's|.*"ParameterValue":"LaunchWizard-\([^"]*\)".*|\1|p' parameters.json)
#AppInstallationSpecification   {"onFailureBehaviour":null,"parameters":{"PRODUCT_ID":"saps4hana-2020","CI_INSTANCE_NR":"00","ASCS_INSTANCE_NR":"01","SAPINST_CD_SAPCAR":"s3://launchwizardbenhou/s4hana2020/SAPCAR","SAPINST_CD_SWPM":"s3://launchwizardbenhou/s4hana2020/SWPM","SAPINST_CD_KERNEL":"s3://launchwizardbenhou/s4hana2020/Kernel","SAPINST_CD_LOAD":"s3://launchwizardbenhou/s4hana2020/Exports","SAPINST_CD_RDBMS":"s3://launchwizardbenhou/s4hana2020/HANA_DB_Software","SAPINST_CD_RDBMS_CLIENT":"s3://launchwizardbenhou/s4hana2020/HANA_Client_Software"}}
SAP_SAPCAR_SOFTWARE_S3_BUCKET=$(sed -n 's|.*"SAPINST_CD_SAPCAR":"\([^"]*\)".*|\1|p' parameters.json)
SAP_SWPM_SOFTWARE_S3_BUCKET=$(sed -n 's|.*"SAPINST_CD_SWPM":"\([^"]*\)".*|\1|p' parameters.json)
SAP_KERNEL_SOFTWARE_S3_BUCKET=$(sed -n 's|.*"SAPINST_CD_KERNEL":"\([^"]*\)".*|\1|p' parameters.json)
SAP_EXPORT_SOFTWARE_S3_BUCKET=$(sed -n 's|.*"SAPINST_CD_LOAD":"\([^"]*\)".*|\1|p' parameters.json)
SAP_RDB_SOFTWARE_S3_BUCKET=$(sed -n 's|.*"SAPINST_CD_RDBMS":"\([^"]*\)".*|\1|p' parameters.json)
SAP_RDBCLIENT_SOFTWARE_S3_BUCKET=$(sed -n 's|.*"SAPINST_CD_RDBMS_CLIENT":"\([^"]*\)".*|\1|p' parameters.json)

if [ -z "$SAP_CI_HOSTNAME" ]
then
  SAP_CI_HOSTNAME=$SAP_HANA_HOSTNAME
fi

echo -e " ${GREEN}...done!${NO_COLOR}"

echo -n "Fetch SAP MASTER PW from Secrets Manager"

DB_SECRET_ID=$(sed -n 's|.*"ParameterKey":"HANAMasterPassKey", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)

if [ -z "$DB_SECRET_ID" ]
then
  DB_SECRET_ID=$(sed -n 's|.*"ParameterKey":"DatabasePasswordKey", "ParameterValue":"\([^"]*\)".*|\1|p' parameters.json)
fi

MASTER_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ID --query 'SecretString')
MASTER_PASSWORD=$(sed -e 's/^"//' -e 's/"$//' <<<"$MASTER_PASSWORD")

echo -e " ${GREEN}...done!${NO_COLOR}"

echo ""
echo "Generating Output..."
echo ""

echo "StackId: "$StackId;
echo "StackName: "$StackName;
echo "StackNotificationARNs: "$StackNotificationARNs;
echo ""
echo "EC2_INSTANCE_ID: "$EC2_INSTANCE_ID;
echo "VPC_ID: "$VPC_ID;
echo "SUBNET_ID: "$SUBNET_ID;
echo "SECURITYGROUPS: "$SECURITYGROUP;
echo ""
echo "LW_DEPLOYMENT_NAME: "$LW_DEPLOYMENT_NAME;
echo "LW_DEPLOYMENT_SCENARIO: "$LW_DEPLOYMENT_SCENARIO;
echo ""
echo "SAP_PRODUCT_ID: "$SAP_PRODUCT_ID;
echo "SAP_SID: "$SAP_SID;
echo "SAP_CI_INSTANCE_NR: "$SAP_CI_INSTANCE_NR;
echo "SAP_CI_HOSTNAME: "$SAP_CI_HOSTNAME;
echo "SAP_HANA_SID: "$SAP_HANA_SID;
echo "SAP_HANA_INSTANCE_NR: "$SAP_HANA_INSTANCE_NR;
echo "SAP_HANA_HOSTNAME: "$SAP_HANA_HOSTNAME;
echo "DB_SECRET_ID: "$DB_SECRET_ID;
echo ""
echo "SAP_SAPCAR_SOFTWARE_S3_BUCKET: "$SAP_SAPCAR_SOFTWARE_S3_BUCKET;
echo "SAP_SWPM_SOFTWARE_S3_BUCKET: "$SAP_SWPM_SOFTWARE_S3_BUCKET;
echo "SAP_KERNEL_SOFTWARE_S3_BUCKET: "$SAP_KERNEL_SOFTWARE_S3_BUCKET
echo "SAP_EXPORT_SOFTWARE_S3_BUCKET: "$SAP_EXPORT_SOFTWARE_S3_BUCKET;
echo "SAP_RDB_SOFTWARE_S3_BUCKET: "$SAP_RDB_SOFTWARE_S3_BUCKET;
echo "SAP_RDBCLIENT_SOFTWARE_S3_BUCKET: "$SAP_RDBCLIENT_SOFTWARE_S3_BUCKET;

echo -e "${GREEN}...all done!${NO_COLOR}"

rm parameters.json