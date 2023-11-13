# SSM for SAP Registration

Registers SAP HANA database as part of Launch Wizard deployment with [AWS Systems Manager for SAP](https://docs.aws.amazon.com/ssm-sap/latest/userguide/get-started.html).

## Prerequisites (Once only)

- Attach the **AWSSystemsManagerForSAPFullAccess** policy to role **AmazonEC2RoleForLaunchWizard**
- Create and attach the provided [IAM Policy](iam_policy.json) to role **AmazonEC2RoleForLaunchWizard**

## Usage via AWS Launch Wizard for SAP

In AWS Launch Wizard for SAP, proceed to **Configure deployment model**. 
In section **Pre-deployment configuration script**, choose the following Amazon S3 URL as script location:

```bash
s3://aws-sap-automation/ssm-sap/run.sh
```

Make sure to **untick** "Proceed with deployment in the event of a configuration script failure"

## Troubleshooting

- Check [Launch Wizard Post-deployment script Log](https://docs.aws.amazon.com/launchwizard/latest/userguide/launch-wizard-sap-troubleshooting.html#launch-wizard-sap-troubleshooting-scripts)
- Check [SSM for SAP - Run Command Log](https://eu-central-1.console.aws.amazon.com/systems-manager/run-command/executing-commands?region=eu-central-1)
- You can run 'aws ssm-sap deregister-application --application-id \<SAP_SID\>' to re-register

## Considerations

- Not supported for HA configurations!
- Currently only HANA database is supported!
- Only tested for SLES!