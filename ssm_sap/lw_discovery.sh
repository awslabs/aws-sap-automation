#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: AWS Launch Wizard for SAP - PostConfiguration script to register single-node HANA and/or SAP AppSrv with SSM for SAP 
#https://docs.aws.amazon.com/ssm-sap/latest/userguide/what-is-ssm-for-sap.html
#EXECUTE: Can be run from any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: mtoerpe@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/lw_bootstrap.sh"

#RUN ONLY IN CASE OF HANA DB
MYPID=$(pidof hdbindexserver)

if [[ $MYPID ]]
then

#SLES ONLY: Fix for "ImportError: cannot import name 'SCHEME_KEYS'"
OS=$(grep '^NAME' /etc/os-release)
if [[ $OS = 'NAME="SLES"' ]] 
then
sudo zypper -n rm python3-pip
sudo rm -fr /usr/lib/python3.6/site-packages/pip*
sudo zypper -n in python3-pip
fi

#INSTALL LATEST BOTO3
pip3 install boto3 --upgrade

#ADD TAG SSMForSAPManaged=True
echo "Tagging EC2 instance!"
aws ec2 create-tags --resources $EC2_INSTANCE_ID --tags Key=SSMForSAPManaged,Value=True

#CREATE NEW SECRET IF NOT EXISTS
DB_SECRET_NAME=$(aws secretsmanager describe-secret --secret-id $DB_SECRET_ID --query 'Name' --output text)
DB_SECRET_NAME_SSM=$(aws secretsmanager describe-secret --secret-id $DB_SECRET_NAME-SSMSAP --query 'Name' --output text)

if [[ $DB_SECRET_NAME_SSM = "" ]]
then
echo "Create a new secret for SSM for SAP!"
EC2_ROLE=$(aws sts get-caller-identity --query "Arn" --output text)
echo '{"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "'$EC2_ROLE'"
                ]
            },
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "*"
        }
    ]
}' > mypolicy.json
DB_SECRET_NAME_SSM=$(aws secretsmanager create-secret \
    --name $DB_SECRET_NAME-SSMSAP \
    --description "Use with SSM for SAP" \
    --secret-string "{\"username\":\"SYSTEM\",\"password\":\"$MASTER_PASSWORD\"}" --query 'Name' --output text)
RES_POLICY=$(aws secretsmanager put-resource-policy \
    --secret-id $DB_SECRET_NAME_SSM \
    --resource-policy file://mypolicy.json \
    --block-public-policy)
rm mypolicy.json
fi

StackNameClean=$(echo "$StackName" | tr -d -)
StackNameClean=$(echo "$StackNameClean" | tr -d _)

#REGISTER SAP HANA
echo "Registering SAP HANA..."
MYSTATUS=$(aws ssm-sap register-application \
--application-id $StackNameClean$SAP_HANA_SID \
--application-type "HANA" \
--instances $EC2_INSTANCE_ID \
--sap-instance-number $SAP_HANA_INSTANCE_NR \
--sid $SAP_HANA_SID \
--credentials '[{"DatabaseName":"'$SAP_HANA_SID'/'$SAP_HANA_SID'","CredentialType":"ADMIN","SecretId":"'$DB_SECRET_NAME_SSM'"},{"DatabaseName":"'$SAP_HANA_SID'/SYSTEMDB","CredentialType":"ADMIN","SecretId":"'$DB_SECRET_NAME_SSM'"}]')

sleep 120

MYSTATUS=$(aws ssm-sap get-application --application-id $StackNameClean$SAP_HANA_SID --query "*.Status" --output text)

if [[ $MYSTATUS != "ACTIVATED" ]]
then
echo "Registration failed!"
exit 1
else
echo "Registration successful!"
fi

aws ssm-sap get-application --application-id $StackNameClean$SAP_HANA_SID

#VERIFY SAP HANA
MYCOMP=$(aws ssm-sap get-application --application-id $StackNameClean$SAP_HANA_SID --output text --query "*.Components[0]")
aws ssm-sap get-component --application-id $StackNameClean$SAP_HANA_SID --component-id $MYCOMP

#RUN ONLY IN CASE OF SAP APPSRV & HANA/SINGLE NODE
if [ -d /usr/sap/$SAP_SID ] && [ $LW_DEPLOYMENT_SCENARIO = "SapNWOnHanaSingle" ]; then

HOSTCTRL=$(sudo /usr/sap/hostctrl/exe/saphostctrl -function GetCIMObject -enuminstances SAPInstance -format json)
echo $HOSTCTRL

#WAIT FOR SAPHOSTCTRL
until [[ "$HOSTCTRL" =~ .*"ABAP Instance".* ]];
do
echo "Waiting for saphostctrl..."
sleep 60
if [[ $(sudo /usr/sap/hostctrl/exe/saphostctrl -function GetCIMObject -enuminstances SAPInstance -format json) =~ .*"ABAP Instance".* ]]; then
    echo "...ready!"
    break
fi
done

SAPCTRL=$(sudo /usr/sap/hostctrl/exe/sapcontrol -nr $SAP_CI_INSTANCE_NR -function GetSystemInstanceList)
echo $SAPCTRL

DB_ARN=$(aws ssm-sap list-databases --application-id $StackNameClean$SAP_HANA_SID --query "Databases[?DatabaseType=='TENANT'].Arn" --output text)
echo $DB_ARN

#REGISTER SAP ABAP APPLICATION SERVER
echo "Registering SAP ABAP Application Server..."
MYSTATUS_APPSRV=$(aws ssm-sap register-application \
--application-id $StackNameClean$SAP_SID \
--application-type "SAP_ABAP" \
--instances $EC2_INSTANCE_ID \
--sid $SAP_SID \
--database-arn $DB_ARN)

sleep 120

MYSTATUS_APPSRV=$(aws ssm-sap get-application --application-id $StackNameClean$SAP_SID --query "*.Status" --output text)

if [[ $MYSTATUS_APPSRV != "ACTIVATED" ]]
then
echo "Registration failed!"
exit 1
else
echo "Registration successful!"
fi

aws ssm-sap get-application --application-id $StackNameClean$SAP_SID

#VERIFY SAP APPSRV
MYCOMP=$(aws ssm-sap get-application --application-id $StackNameClean$SAP_SID --output text --query "*.Components[0]")
aws ssm-sap get-component --application-id $StackNameClean$SAP_SID --component-id $MYCOMP

fi



fi
echo "All done!"