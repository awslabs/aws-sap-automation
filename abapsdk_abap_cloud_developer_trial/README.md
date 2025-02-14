# AWS SDK for SAP ABAP installer for the SAP Cloud Developer Trial (Docker)

Deploys the AWS SDK for SAP ABAP on the [SAP ABAP Cloud Developer Trial @ Docker](https://hub.docker.com/r/sapse/abap-cloud-developer-trial).

Check out https://hub.docker.com/r/sapse/abap-cloud-developer-trial for more details on this trial edition and also SAP's licensing terms.

**Note:** This script has been tested with Amazon Linux 2023 only.

## Prerequisites:

1. Amazon VPC with internet access (e.g. NAT Gateway)
2. Amazon EC2 instance running **Amazon Linux 2023**
3. [SAP ABAP Cloud Developer Trial Docker](https://hub.docker.com/r/sapse/abap-cloud-developer-trial) container already running in your EC2 Instance with a valid SAP license.
4. SAP TMS is configured and activated.
	
This script performs the following:

1. Downloads the AWS SDK for ABAP transport packages into the EC2 instance (/tmp)
2. Unzips the AWS SDK for ABAP transport packages
3. Copies the AWS SDK for ABAP transport packages into the docker image
4. Imports the transports into the ABAP Cloud Developer Trial SAP instance running on docker
	
Please note that the SDK modules to be installed are defined in variable "tla_values" and are currently set as follows:

```bash
tla_values=("core" "lmd" "sqs" "sns" "evb" "tex" "cpd" "xl8" "fcs" "loc" "cwl" "cwt" "cwe" "glu" "dbr" "dyn" "bdk" "bdr" "lr1" "lr2" "rek" "fcq")
```

If you would like to add or remove transports, please edit the setup.sh file and simply adjust "tla_values". For a detailed description of each module in the AWS SDK for ABAP, refer to https://docs.aws.amazon.com/sdk-for-sap-abap/v1/api/latest/tla.html.	

## Getting started

To execute the script, run the following command on OS level:

```bash
cd /tmp
wget https://raw.githubusercontent.com/awslabs/aws-sap-automation/refs/heads/main/abapsdk_abap_cloud_developer_trial/setup.sh
chmod +x setup.sh
./setup.sh docker_setup
CONTAINER_ID=$(docker ps -q)
docker exec -it $CONTAINER_ID sudo su - a4hadm -c '/tmp/setup.sh sap_setup'
```

## Troubleshooting

Check [Troubleshoot AWS SDK for SAP ABAP](https://docs.aws.amazon.com/sdk-for-sapabap/latest/developer-guide/troubleshoot.html)

## Considerations

Currently, 22 AWS ABAP SDK transports are added to the SAP system's transport queue
Transports are imported with **Ignore Invalid Component Version** and **Overwrite Originals** options set