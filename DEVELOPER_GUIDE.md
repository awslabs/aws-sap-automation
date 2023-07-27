# Developer Guide

Do you like to develop and contribute your own pre- or post-configuration script(s) for AWS Launch Wizard for SAP?

This is your walkthrough:

1. Copy/fork this repository
2. Study the [lw_bootstrap](utils/lw_bootstrap.sh) script for available parameters, describing the SAP environment
3. Create a new subfolder and build your script either in **bash** or **python** following the [software_download](software_download/) example
4. Deploy a SapNWOnHanaSingle Stack via AWS Launch Wizard for SAP and test your script
5. Create pull request or submit a feature request including your code and test results