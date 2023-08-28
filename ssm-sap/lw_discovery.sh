#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: AWS Launch Wizard for SAP - PostConfiguration script to register HDB with SSM for SAP 
#https://docs.aws.amazon.com/ssm-sap/latest/userguide/what-is-ssm-for-sap.html
#EXECUTE: Can be run only via AWS Launch Wizard for SAP
#AUTHOR: mtoerpe@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/lw_bootstrap.sh"

#RUN ONLY IN CASE OF HANA DB
MYPID=$(pidof hdbindexserver)

if [[ $MYPID ]]
then

#SUSE Fix for ImportError: cannot import name 'SCHEME_KEYS'
sudo zypper -n rm python3-pip
sudo rm -fr /usr/lib/python3.6/site-packages/pip*
sudo zypper -n in python3-pip

#ADD TAG SSMForSAPManaged=True
echo "Tagging EC2 instance!"
aws ec2 create-tags --resources $EC2_INSTANCE_ID --tags Key=SSMForSAPManaged,Value=True

#CREATE NEW SECRET IF NOT EXISTS
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
HANA_SECRET_NAME=$(aws secretsmanager describe-secret --secret-id $HANA_SECRET_ID --query 'Name' --output text)
HANA_SECRET_ID_SSM=$(aws secretsmanager create-secret \
    --name $HANA_SECRET_NAME-SSMSAP \
    --description "Use with SSM for SAP" \
    --secret-string "{\"username\":\"ADMIN\",\"password\":\"$MASTER_PASSWORD\"}" --query 'Name' --output text)
aws secretsmanager put-resource-policy \
    --secret-id $HANA_SECRET_ID_SSM \
    --resource-policy file://mypolicy.json \
    --block-public-policy
rm mypolicy.json

#REGISTER APPLICATION
echo "Registering Application..."
MYSTATUS=$(aws ssm-sap register-application \
--application-id $SAP_SID \
--application-type HANA \
--instances $EC2_INSTANCE_ID \
--sap-instance-number $SAP_HANA_INSTANCE_NR \
--sid $SAP_HANA_SID \
--credentials '[{"DatabaseName":"'$SAP_HANA_SID'/'$SAP_HANA_SID'","CredentialType":"ADMIN","SecretId":"'$HANA_SECRET_ID_SSM'"},{"DatabaseName":"'$SAP_HANA_SID'/SYSTEMDB","CredentialType":"ADMIN","SecretId":"'$HANA_SECRET_ID_SSM'"}]')

sleep 120

aws ssm-sap get-application --application-id $SAP_SID
MYSTATUS=$(aws ssm-sap get-application --application-id $SAP_SID --query "*.Status" --output text)

if [[ $MYSTATUS -eq "ACTIVATED" ]]
then
echo "Registration successful!"
else
echo "Registration failed!"
exit 1
fi

fi