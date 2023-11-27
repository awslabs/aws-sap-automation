# SSM for SAP Registration

Registers SAP HANA database and/or SAP ABAP Application Server **single-node** deployments as part of Launch Wizard deployment with [AWS Systems Manager for SAP](https://docs.aws.amazon.com/ssm-sap/latest/userguide/get-started.html).

## Prerequisites (Once only)

- Attach the **AWSSystemsManagerForSAPFullAccess** policy to role **AmazonEC2RoleForLaunchWizard**
- Create and attach the provided [IAM Policy](iam_policy.json) to role **AmazonEC2RoleForLaunchWizard**

## Usage via AWS Launch Wizard for SAP

In AWS Launch Wizard for SAP, proceed to **Configure deployment model**. 
In section **Post-deployment configuration script**, choose the following Amazon S3 URL as script location:

```bash
s3://aws-sap-automation/ssm_sap/run.sh
```

The result looks as follows. Click 'next' to complete the wizard.

![image](lw_post_script.png)

## Usage post-deployment

Execute the following lines on your **EC2 Instance**:

```bash
cd /
mkdir -p aws-sap-automation
cd aws-sap-automation
aws s3 cp s3://aws-sap-automation/ssm_sap/ ./ssm_sap --recursive
aws s3 cp s3://aws-sap-automation/utils/ ./utils --recursive
chmod +x utils/colors.sh
chmod +x utils/lw_bootstrap.sh
chmod +x ssm_sap/lw_discovery.sh
cd ssm_sap
./lw_discovery.sh
```

## Troubleshooting

- Check [Launch Wizard Post-deployment script Log](https://docs.aws.amazon.com/launchwizard/latest/userguide/launch-wizard-sap-troubleshooting.html#launch-wizard-sap-troubleshooting-scripts)
- Check [SSM for SAP - Run Command Log](https://eu-central-1.console.aws.amazon.com/systems-manager/run-command/executing-commands?region=eu-central-1)
- You can run 'aws ssm-sap deregister-application --application-id \<SAP_SID\>' to re-register

## Considerations

- Currently only single-node deployments are supported!
- SAP Application Server registration depends on saphostctrl information
- By default, you can only register up to 10 applications. For more make sure to increase you quota.