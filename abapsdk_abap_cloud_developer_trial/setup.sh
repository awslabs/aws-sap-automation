#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Script for setting up SAP Cloud Trial docker image on Amazon Linux with the AWS ABAP SDK
#AUTHOR: joabozel@ & decril@

CONTAINER_ID=$(docker ps -q)

# Environment Variables
SAP_SID=A4H
SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')

function download_aws_abap_sdk ()
{
    # Install unzip in Amazon Linux host:
    yum install unzip -y
    # Download the AWS ABAP SDK
    # Create temporary directory for ABAP SDK download:
    mkdir -p /tmp/aws-abapsdk
    # Download ABAP SDK files:
    curl -o /tmp/abapsdk-LATEST.zip https://sdk-for-sapabap.aws.amazon.com/awsSdkSapabapV1/release/abapsdk-LATEST.zip
    # Unzip the ABAP SDK files with overwrite option:
    unzip -o /tmp/abapsdk-LATEST.zip -d /tmp/aws-abapsdk
    # Copy the ABAP SDK files to the SAP Docker filesystems:
    docker cp /tmp/aws-abapsdk/ $CONTAINER_ID:/tmp/
    # Update permissions of the ABAP SDK files:
    docker exec -it $CONTAINER_ID chown -R $SAP_SIDADM:sapsys /tmp/aws-abapsdk/
    docker exec -it $CONTAINER_ID chmod -R 744 /tmp/aws-abapsdk/
    docker cp /tmp/aws-sap-dockersetup.sh $CONTAINER_ID:/tmp/
    docker exec -it $CONTAINER_ID chown -R $SAP_SIDADM:sapsys /tmp/aws-sap-dockersetup.sh
    docker exec -it $CONTAINER_ID chmod -R 744 /tmp/aws-sap-dockersetup.sh
}

function import_aws_abap_sdk ()
{
    SAP_SID=A4H
    AWS_SDK_PATH="/tmp/aws-abapsdk"
    TPDIR="/sapmnt/$SAP_SID/exe/uc/linuxx86_64"
    JSON_FILE="$AWS_SDK_PATH/META-INF/sdk_index.json"
    TPPROFILE="/usr/sap/trans/bin/TP_DOMAIN_$SAP_SID.PFL"
    TPSTATUS="/usr/sap/trans/log/tpstatus.log" 
    CLNT=001

    # The transports imported in the system will depend on the value of the variable "tla_values". For each module, a transport will be imported
    # into the SAP system. Please note that the module "core" is mandatory and should be the first value for the variable "tla_values".
    # For the detailed list of modules available, refer to the AWS documentation: https://docs.aws.amazon.com/sdk-for-sap-abap/v1/api/latest/tla.html
    tla_values=("core" "lmd" "sqs" "sns" "evb" "tex" "cpd" "xl8" "fcs" "loc" "cwl" "cwt" "cwe" "glu" "dbr" "dyn" "bdk" "bdr" "lr1" "lr2" "rek" "fcq")

    # Copy necessary files to transport directory
    for transport in "${tla_values[@]}"; do
      # Copy files starting with "R*" to DATA directory
      find "$AWS_SDK_PATH/transports/$transport" -type f -name "R*" -exec cp -pr {} /usr/sap/trans/data/ \;
      # Copy files starting with "K*" to COFILES directory
      find "$AWS_SDK_PATH/transports/$transport" -type f -name "K*" -exec cp -pr {} /usr/sap/trans/cofiles/ \;
    done

    # Loop through each "tla" value
    for tla_to_find in "${tla_values[@]}"; do
      # Use grep, awk, and sed to extract the "transport" value for the specified "tla"
      transport_value=$(grep -A 2 "\"$tla_to_find\":" "$JSON_FILE" | grep "transport" | awk -F' ' '{print $2}' | sed 's/[",]//g')

      # Check if the transport_value is not empty
      if [ -n "$transport_value" ]; then
        echo "Transport for $tla_to_find: $transport_value"
        # Add the transport to the buffer
        $TPDIR/tp addtobuffer "$transport_value" $SAP_SID CLIENT=$CLNT pf=$TPPROFILE
        RC=$?

        if [ "$RC" -eq 0 ]; then
          echo "`date`...Transport $transport_value added to buffer successfully." >> ${TPSTATUS}
        else
          echo "`date`...Error adding transport $transport_value to buffer. RC=$RC" >> ${TPSTATUS}
        fi
      else
        echo "Transport for $tla_to_find not found."
      fi
    done
	# Import the transports from the buffer
	$TPDIR/tp import all $SAP_SID u1246 pf=$TPPROFILE
	RC=$?

	if [ "$RC" -ge 5 ]; then
		echo "`date`...All Transports imported successfully." >> ${TPSTATUS}
		else
		echo "`date`...Error importing transports RC=$RC" >> ${TPSTATUS}
	fi
}

#----------------------------------
# --- PROCESS INPUT PARAMETERS ---
#----------------------------------

if [[ "$1" = "docker_setup" ]]
then
  download_aws_abap_sdk
  exit 0
elif [[ "$1" = "sap_setup" ]]
then
  import_aws_abap_sdk
  exit 0
else
  echo "Error: Unsupported or missing operation $1";
  exit 1
fi