#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: AWS Launch Wizard for SAP - PreConfiguration script for automatically downloading SAP installation files
#EXECUTE: Can be run from any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: mtoerpe@

cd $home
mkdir aws-sap-automation
cd aws-sap-automation

aws s3 cp s3://aws-sap-automation/software_download/ . --recursive
aws s3 cp s3://aws-sap-automation/utils/ . --recursive
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x software_download/lw_software_download.sh
cd software_download
./lw_software_download.sh