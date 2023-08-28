#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: AWS Launch Wizard for SAP - PostConfiguration script to register HDB with SSM for SAP
#EXECUTE: Can be run from any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: mtoerpe@

cd /
mkdir -p aws-sap-automation
cd aws-sap-automation

aws s3 cp s3://aws-sap-automation/ssm-sap/ ./ssm-sap --recursive
aws s3 cp s3://aws-sap-automation/utils/ ./utils --recursive
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x ssm-sap/lw_discovery.sh
cd ssm-sap
./lw_discovery.sh