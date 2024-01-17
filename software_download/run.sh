#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Script for automatically downloading SAP installation files
#TYPE: AWS Launch Wizard for SAP - PreConfiguration script
#TARGET: SAP DB
#EXECUTE: Can be executed standalone or via AWS Launch Wizard for SAP
#AUTHOR: meyro@, mtoerpe@

cd /
mkdir -p aws-sap-automation
cd aws-sap-automation

aws s3 cp s3://aws-sap-automation/software_download/ ./software_download --recursive --region eu-central-1
aws s3 cp s3://aws-sap-automation/utils/ ./utils --recursive --region eu-central-1
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x software_download/lw_software_download.sh
cd software_download
./lw_software_download.sh