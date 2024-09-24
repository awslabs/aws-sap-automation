# Horizontal Scaling

This script allows you to add additional nodes to a preexisting SAP application deployed with AWS Launch Wizard for SAP, so that you can scale horizontally to meet increased performance requirements.

The following SAP application type and patterns are supported:

| AWS Launch Wizard for SAP application type | Deployment pattern       | Supported scenario                     | AMI required                                  |
| ------------------------------------------ | ------------------------ | -------------------------------------- | --------------------------------------------- |
| SAP NetWeaver on HANA                  | Single/Distributed/HA    | Add an SAP NetWeaver application server node         | PAS/AAS of source deployment                  |
| SAP HANA                                   | Scale-Out | Add a SAP HANA subordinate node | current/subordinate node of source deployment |
| SAP HANA with FSx for NetApp ONTAP                               | Scale-Out | Add a SAP HANA standby or subordinate node | current/subordinate node of source deployment |

## Prerequisites (Once only)

- Initial successful AWS Launch Wizard for SAP deployment
- Create and attach the provided [IAM Policy](iam_policy.json) to role **AmazonEC2RoleForLaunchWizard**

## Prerequisites (Required on every usage)

- Create an up-to-date AMI of your SAP HANA / SAP Application server instance

## How to create an AMI

**Note:** The following best practices for creating an image to add an additional application node to a previously deployed SAP application using Launch Wizard are general guidelines only. They do not represent a complete solution. These recommendations are offered as considerations that may not be appropriate or sufficient for your environment, depending on the activities that you performed on these instances after the Launch Wizard deployment.

**General recommendations:**

* Do not share images with untrusted accounts.
* Do not make public images that contain private or sensitive data.
* Apply all of the latest available operating system security patches.

**Before you create an image:**

* Temporarily disable SAP services for startup:

List all startup processes
```bash
systemctl --all list-unit-files --type=service
```

Disable all SAP related startup processes
```bash
systemctl disable sapinit
systemctl disable SAP<SAPSID><INSTANCENR>.service
```

* If applicable, temporarily disable any third-party applications from starting on boot.
* Keep the file systems and volumes intact, and ensure that the image is bootable if the volumes are not attached. If the volumes are not attached, the /etc/fstab nofail setting must be enabled.
* Perform any other temporary adjustments that you can make that won't impact the boot process.
* Revert to the original values after the image creation has been triggered

**Create the image**

Run the following AWS Command Line Interface command to create an image using the no reboot option.

```bash
aws ec2 create-image --instance-id <EC2InstanceID> --name "`<My server>`" --no-reboot
```

**Note:** This is a asyncronous process and might take several hours to complete!

## Deploy

- How to [SAP NetWeaver on HANA | Single/Distributed/HA | Add an SAP NetWeaver application server node](aas/README.md)
- How to [SAP HANA | Scale-Out | Add a SAP HANA subordinate node](hana_worker/README.md)
- How to [SAP HANA (FSx for NetApp ONTAP) | Scale-Out | Add a SAP HANA standby node](hana_standby/README.md)

## Pre- and post-deployment configuration scripts

As with base node deployments with Launch Wizard for SAP, you can run pre- and post-deployment configuration scripts when you add an additional node. For more information about how Launch Wizard for SAP accesses and deploys these scripts, see [Custom deployment configuration scripts](https://docs.aws.amazon.com/launchwizard/latest/userguide/how-launch-wizard-sap-works.html#launch-wizard-sap-how-it-works-scripts).

**Limits for running pre- and post- deployment configuration scripts**

The following limits apply when running pre- and post- deployment configuration scripts for your new node.

* Only one action can be performed at a time.
* SSM documents that are created at runtime are not deleted. Periodic cleanup of the documents is required.
* Any automation activity performed on the new node is extremely limited. Activities that must be performed on the parent node are called out in the SSM documentation.

## Troubleshooting

- In case the automation failed, check the output/error of the respective commands directly for more information!