#!/bin/sh

# AWS Launch Wizard for SAP - Post Deployment Script to install S/4HANA Fully-activated Appliance (FAA) 
# Please choose LW infrastructure deployment only without SAP installation
# version - 2.0


######### Please set the installation parameters below #########

# S3 URI path for S/4HANA fully-activated appliance .ZIP exports (Do not add / at the end of URI)
# Example: s3://bucket-name/s4hana/2023_FPS00_FAA/exports
s4h_faa_exports="<S3_URI_EXPORTS>"

# S3 URI path for SWPM .SAR file (Do not add / at the end of URI)
# Example: s3://bucket-name/s4hana/2023_FPS00_FAA/swpm
s4h_swpm="<S3_URI_SWPM>"

# S/4 Fully-Activated Appliance Version (Release + Feature Pack Stack Version)
# Example: 2023_FPS00
# Supported Versions: 2023_FPS00 | 2023_FPS02
s4h_version="<S4H_FAA_VERSION>"

##########################################################################################



#========= /// DO NOT modify the script below /// =========#

sudo su -

home_dir="/root/install"
s4h_faa_dir="$home_dir/s4h_faa"
post_deploy_log="$home_dir/post_deploy.log"
install_package_zip="https://github.com/awslabs/aws-sap-automation/raw/refs/heads/main/s4h_faa/s4h_faa_package.zip"


cd $home_dir
touch $post_deploy_log

echo "==================================================" >> $post_deploy_log
echo "$(date)" >> $post_deploy_log
echo " " >> $post_deploy_log
echo "Log file $post_deploy_log successfully created for SAP S/4HANA $s4h_version Fully-Activated Appliance (FAA) installation process" >> $post_deploy_log
echo " " >> $post_deploy_log
echo "$(date +%Y-%m-%d_%H:%M:%S)......Downloading AWS for SAP S/4HANA FAA automated installation package from github..." >> $post_deploy_log

until [[ -f ${home_dir}/s4h_faa.zip ]];do
	wget ${install_package_zip} -O s4h_faa.zip || true
	sleep 5
done

unzip -j ${home_dir}/s4h_faa.zip -d ${s4h_faa_dir}/
chmod -R 775  ${s4h_faa_dir}
rm ${s4h_faa_dir}/._*
rm -f  ${home_dir}/s4h_faa.zip

${s4h_faa_dir}/s4h_faa_install.sh ${s4h_faa_exports} ${s4h_swpm} ${s4h_version}
echo "==================================================" >> $post_deploy_log