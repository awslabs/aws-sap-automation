#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: AWS Launch Wizard for SAP - PostConfiguration script to register single-node HANA and/or SAP AppSrv with SSM for SAP 
#TYPE: AWS Launch Wizard for SAP - PostConfiguration script
#TARGET: SAP DB
#EXECUTE: Can be run from any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: mtoerpe@

cd /
mkdir -p aws-sap-automation
cd aws-sap-automation

aws s3 cp s3://aws-sap-automation/ssm_sap/ ./ssm_sap --recursive --region eu-central-1
aws s3 cp s3://aws-sap-automation/utils/ ./utils --recursive --region eu-central-1
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x ssm_sap/lw_discovery.sh
cd ssm_sap
./lw_discovery.sh