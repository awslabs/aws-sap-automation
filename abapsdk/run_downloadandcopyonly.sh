#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Script for automatically downloading AWS SDK for SAP ABAP files and importing them into the SAP system installed by the AWS Launch Wizard
#TYPE: AWS Launch Wizard for SAP - PostConfiguration script
#TARGET: SAP PAS
#EXECUTE: Can be executed standalone or via AWS Launch Wizard for SAP
#AUTHOR: meyro@

cd /tmp
mkdir -p aws-sap-automation
cd aws-sap-automation

aws s3 cp s3://aws-sap-automation/abapsdk/ ./abapsdk --recursive --region eu-central-1
aws s3 cp s3://aws-sap-automation/utils/ ./utils --recursive --region eu-central-1
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x abapsdk/lw_abapsdk.sh
cd abapsdk
./lw_abapsdk.sh lwpostscript downloadandcopy