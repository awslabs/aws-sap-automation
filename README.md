# SAP on AWS Automation Scripts

Collection of scripts, that can be used primarily with **AWS Launch Wizard for SAP** to automate the following tasks:

| Feature  | Description |
| ------------- | ------------- |
| **[SAP Software Download](software_download/)**  | Makes all [required SAP software](https://docs.aws.amazon.com/launchwizard/latest/userguide/launch-wizard-sap-software-install-details.html) available to AWS Launch Wizard for SAP deployments |
| **[SSM for SAP](ssm_sap/) (RETIRED)** | Performs [AWS Systems Manager for SAP](https://docs.aws.amazon.com/ssm-sap/latest/userguide/get-started.html) registration for AWS Launch Wizard for SAP deployments |
| **[Custom Tags](tagging/)** | Adds a set of predefined custom tags to all AWS Launch Wizard for SAP deployment resources |
| **[AWS SDK for SAP ABAP installer](abapsdk/)** | Downloads latest version and (optional) runs import @ AWS Launch Wizard for SAP deployments |
| **[AWS SDK for SAP ABAP installer @ SAP ABAP Cloud Developer Trial Edition](abapsdk_abap_cloud_developer_trial/)** | Downloads latest version and runs import @ SAP ABAP Cloud Developer Trial Edition |
| **[Horizontal Scaling](scale_nodes/)** | Add additional nodes to a preexisting SAP application deployed with AWS Launch Wizard for SAP |
| **[SAP S/4HANA Fully-Activated Appliance (FAA)](s4h_faa/)** | Automated installation of the SAP S/4HANA Fully-Activated Appliance (FAA) through AWS Launch Wizard |

[![SAP software](https://github.com/awslabs/aws-sap-automation/actions/workflows/software_download_all.yml/badge.svg)](https://github.com/awslabs/aws-sap-automation/actions/workflows/software_download_all.yml) <br>
[![s4hana-2023](https://github.com/awslabs/aws-sap-automation/actions/workflows/launch_wizard_s4hana2023.yml/badge.svg)](https://github.com/awslabs/aws-sap-automation/actions/workflows/launch_wizard_s4hana2023.yml) <br>
[![solman72ase](https://github.com/awslabs/aws-sap-automation/actions/workflows/launch_wizard_solman72_ase.yml/badge.svg)](https://github.com/awslabs/aws-sap-automation/actions/workflows/launch_wizard_solman72_ase.yml) <br>
[![s4hanafoundations-2023-multi-fsx](https://github.com/awslabs/aws-sap-automation/actions/workflows/launch_wizard_s4hanafnd2023.yml/badge.svg)](https://github.com/awslabs/aws-sap-automation/actions/workflows/launch_wizard_s4hanafnd2023.yml) <br>

## Found an issue? Anything to add?

See [CONTRIBUTING](CONTRIBUTING.md) and [DEVELOPER_GUIDE](DEVELOPER_GUIDE.md) for more information.

## License

This project is licensed under  [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](.LICENSE)
  
All rights reserved.