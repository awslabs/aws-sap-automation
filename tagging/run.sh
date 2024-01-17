#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Applies a list of custom tags onto all related resources of a given Lauch Wizard for SAP deployment.
#TYPE: AWS Launch Wizard for SAP - PostConfiguration script
#TARGET: SAP ASCS/PAS
#EXECUTE: Can be executed on any EC2 instance, that has been provisioned by AWS Launch Wizard for SAP
#AUTHOR: cspruell@

cd /tmp
mkdir -p aws-sap-automation
cd aws-sap-automation

aws s3 cp s3://aws-sap-automation/tagging/ ./tagging --recursive --region eu-central-1
aws s3 cp s3://aws-sap-automation/utils/ ./utils --recursive --region eu-central-1
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x tagging/lw_tagging.sh
cd tagging
./lw_tagging.sh

rm /tmp/aws-sap-automation -R