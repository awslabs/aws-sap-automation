#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Script for automatically downloading SAP installation files
#EXECUTE: Can be run standalone or via AWS Launch Wizard for SAP
#AUTHOR: meyro@, mtoerpe@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/colors.sh"

# --- INPUT ---
echo ""

FLAG_VALIDATE=false
FLAG_DOWNLOAD=false

if [[ "$1" = "validate" ]]
then
   FLAG_VALIDATE=true
   SAP_PRODUCT_ID=${2}
   echo "Validate Download Links: $FLAG_VALIDATE";
elif [[ "$1" = "download" ]]
then
   FLAG_DOWNLOAD=true
   SAP_PRODUCT_ID=${2}
   LW_DEPLOYMENT_NAME=${SAP_PRODUCT_ID}
   echo "LW_DEPLOYMENT_NAME: "$LW_DEPLOYMENT_NAME;
   S3_BUCKET_PREFIX=${3}

   SAP_SAPCAR_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/SAPCAR"
   SAP_SWPM_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/SWPM"
   SAP_KERNEL_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/KERNEL"
   SAP_EXPORT_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/EXPORT"
   SAP_HANADB_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/HANADB"
   SAP_HANACLIENT_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/HANADBCLIENT"

   echo "SAP_SAPCAR_SOFTWARE_S3_BUCKET: "$SAP_SAPCAR_SOFTWARE_S3_BUCKET;
   echo "SAP_SWPM_SOFTWARE_S3_BUCKET: "$SAP_SWPM_SOFTWARE_S3_BUCKET;
   echo "SAP_KERNEL_SOFTWARE_S3_BUCKET: "$SAP_KERNEL_SOFTWARE_S3_BUCKET;
   echo "SAP_EXPORT_SOFTWARE_S3_BUCKET: "$SAP_EXPORT_SOFTWARE_S3_BUCKET;
   echo "SAP_HANADB_SOFTWARE_S3_BUCKET: "$SAP_HANADB_SOFTWARE_S3_BUCKET;
   echo "SAP_HANACLIENT_SOFTWARE_S3_BUCKET: "$SAP_HANACLIENT_SOFTWARE_S3_BUCKET;
fi

# --- Retrieving LW CloudFormation stack variables ---

if [[ $FLAG_VALIDATE != true && $FLAG_DOWNLOAD != true ]]
then
source ../utils/lw_bootstrap.sh
fi

echo ""
echo "---------------------------------------------------"
echo "LW Software Download Script"
echo "---------------------------------------------------"
echo ""

# --- Read S-USER ---

echo "Retrieving SAP S-User Credentials from AWS Secrets Manager..."
echo ""

S_USER=$(aws secretsmanager get-secret-value --secret-id sap-s-user --query SecretString --output text | grep -oP '(?<="username":")[^"]*')
S_PASS=$(aws secretsmanager get-secret-value --secret-id sap-s-user --query SecretString --output text | grep -oP '(?<="password":")[^"]*')

if [ -z "$S_USER" ]
then
  echo -e "${RED}Error:${NO_COLOR} Secret sap-s-user or properties username/password not found! Check AWS Secrets Manager!"
  exit 1
fi

# --- Validate S-USER ---

echo -n "Validating SAP S-User"
CHECK_URL="https://softwaredownloads.sap.com/file/0020000001450632021" #SAPEXE_50-80005374.SAR from S/4HANA 2021
RETURNCODE=`wget -q -r -U "SAP Download Manager" --timeout=30 --server-response --spider --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $CHECK_URL 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}'`

if [[ $RETURNCODE -ne 200 && $RETURNCODE -ne 302 ]]
then 
  echo -e "${RED}Error:${NO_COLOR} SAP S-User username/password invalid! (HTTP "${RETURNCODE}")" 
  exit 1
fi

echo -e " ${GREEN}...success!${NO_COLOR}"

echo ""

# LW DOCS --> https://docs.aws.amazon.com/launchwizard/latest/userguide/launch-wizard-sap-software-install-details.html

### CHECK THESE LINKS FOR VALIDITY AS SAP FREQUENTLY DELETES OLDER VERSIONS FROM THE SAP SUPPORT PORTAL
SAPCAR="https://softwaredownloads.sap.com/file/0020000000098642022"                          # SAPCAR_1115-70006178.EXE           
SAPCAR_MD5="765412436934362cc5497e3d659fbb78be91093a091c11ec4fbe84dfb415a0e5"
SWPM_1_0="https://softwaredownloads.sap.com/file/0020000000855242023"                        # SWPM10SP38_0-20009701.SAR        
SWPM_1_0_MD5="a29bcfaa12a9854db6078155a6f0f4ac317fd8c911a3dda4edf70dab1f2b7a8b"
SWPM_2_0="https://softwaredownloads.sap.com/file/0020000000855532023"                        # SWPM20SP15_3-80003424.SAR      
SWPM_2_0_MD5="52bcc81a58c3fbcf141e2bed8193f273ee74203ecf905006701d053c414114ee"

HANADB_LATEST="https://softwaredownloads.sap.com/file/0030000000783582023"                    # 51056821.ZIP - SAP HANA Platform Edt. 2.0 SPS07 rev71 Linux x86_64
HANADB_LATEST_MD5="7364bd72e6acd393f9198397476c4f5dd855eb2c764081837595fe77d1ef59e1"

HANACLIENT_LATEST="https://softwaredownloads.sap.com/file/0020000000516362023"                # IMDB_CLIENT20_016_26-80002082.SAR - SAP HANA CLient 2.16
HANACLIENT_LATEST_MD5="d238143b22ab5976221ab7d89b097690dd7af9fc75445c1f78eeb7196c569ca4"


### SWPM_1_0
SWPM_1_0_SWPM=${SWPM_1_0}                                                                         
SWPM_1_0_SWPM_MD5=${SWPM_1_0_MD5} 


### SWPM_2_0
SWPM_2_0_SWPM=${SWPM_2_0}                                                                         
SWPM_2_0_SWPM_MD5=${SWPM_2_0_MD5} 


### HANA_CLIENT
HANA_CLIENT_SWPM=${HANACLIENT_LATEST}                                                                         
HANA_CLIENT_SWPM_MD5=${HANACLIENT_LATEST_MD5} 


### NetWeaver 7.50
NW750_SAPCAR=${SAPCAR}                                                                     
NW750_SAPCAR_MD5=${SAPCAR_MD5}
NW750_SWPM=${SWPM_1_0}                                                                         
NW750_SWPM_MD5=${SWPM_1_0_MD5} 
NW750_HANADB=${HANADB_LATEST}                                                               
NW750_HANADB_MD5=${HANADB_LATEST_MD5}
NW750_HANACLIENT=${HANACLIENT_LATEST}
NW750_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
NW750_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000000635092016"             # 51050829_3.ZIP                        (according to LW docs)
NW750_EXPORT_PART1_MD5="06c3a3cd5d1ad266f61ca202552468501d94cfdc7641ffdadf0a9abad82b648a"
NW750_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001632902020"            # igsexe_12-80003187.sar                (according to LW docs)
NW750_KERNEL_IGSEXE_MD5="414ab4e14e3985e03dfbc1fcc8fdfe66b0972cfcbbacf80fc4b46c93f20a557e"
NW750_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"         # igshelper_17-10010245.sar             (according to LW docs)
NW750_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
NW750_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001523262020"            # SAPEXE_700-80002573.SAR               (according to LW docs)
NW750_KERNEL_SAPEXE_MD5="0aa8fd962c91674f7cb082d3e1d980207dc853bcce4abcb2da9a33f2b7683fdb"
NW750_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001523902020"          # SAPEXEDB_700-80002572.SAR             (according to LW docs)
NW750_KERNEL_SAPEXEDB_MD5="ebea79b86776d5b14ec03bcd6e473982196d2ceb7c9828e38fa8fa40fa6038e4"
NW750_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"      # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
NW750_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"


### NetWeaver 7.52
NW752_SAPCAR=${SAPCAR}                                                                           
NW752_SAPCAR_MD5=${SAPCAR_MD5}
NW752_SWPM=${SWPM_1_0}                                                                       
NW752_SWPM_MD5=${SWPM_1_0_MD5} 
NW752_HANADB=${HANADB_LATEST}                                                                   
NW752_HANADB_MD5=${HANADB_LATEST_MD5}
NW752_HANACLIENT=${HANACLIENT_LATEST}
NW752_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
NW752_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000019659142017"             # S4CORE107_INST_EXPORT_1.exe                    (according to LW docs)
NW752_EXPORT_PART1_MD5="399228ad1ede56ea97a4676e5cfd9ff2ebccded55b8128718029188bc704682e"
NW752_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000019659152017"             # S4CORE107_INST_EXPORT_2.rar                    (according to LW docs)
NW752_EXPORT_PART2_MD5="d968835cadfea8514a552ec977421043649bbb59140629a9dd897a7f0c47480b"
NW752_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001632902020"            # igsexe_12-80003187.sar                (according to LW docs)
NW752_KERNEL_IGSEXE_MD5="414ab4e14e3985e03dfbc1fcc8fdfe66b0972cfcbbacf80fc4b46c93f20a557e"
NW752_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"         # igshelper_17-10010245.sar             (according to LW docs)
NW752_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
NW752_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001523262020"            # SAPEXE_700-80002573.SAR               (according to LW docs)
NW752_KERNEL_SAPEXE_MD5="0aa8fd962c91674f7cb082d3e1d980207dc853bcce4abcb2da9a33f2b7683fdb"
NW752_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001523902020"          # SAPEXEDB_700-80002572.SAR             (according to LW docs)
NW752_KERNEL_SAPEXEDB_MD5="ebea79b86776d5b14ec03bcd6e473982196d2ceb7c9828e38fa8fa40fa6038e4"
NW752_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"      # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
NW752_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"


### NetWeaver 7.50 (JAVA)
NW750_JAVA_SAPCAR=${SAPCAR}                                                                            
NW750_JAVA_SAPCAR_MD5=${SAPCAR_MD5}
NW750_JAVA_SWPM=${SWPM_1_0}                                                                          
NW750_JAVA_SWPM_MD5=${SWPM_1_0_MD5} 
NW750_JAVA_HANADB=${HANADB_LATEST}                                                                   
NW750_JAVA_HANADB_MD5=${HANADB_LATEST_MD5}
NW750_JAVA_HANACLIENT=${HANACLIENT_LATEST}
NW750_JAVA_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
NW750_JAVA_EXPORT_PART1="https://softwaredownloads.sap.com/file//0030000000231172022"            # 51055106.ZIP                          (according to LW docs)
NW750_JAVA_EXPORT_PART1_MD5="6cf18b4ab1d1d48809e3103810ccf3f0c73ca4bce6b92b6b187aff27a044d21b"
NW750_JAVA_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001632902020"            # igsexe_12-80003187.sar                (according to LW docs)
NW750_JAVA_KERNEL_IGSEXE_MD5="414ab4e14e3985e03dfbc1fcc8fdfe66b0972cfcbbacf80fc4b46c93f20a557e"
NW750_JAVA_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"         # igshelper_17-10010245.sar             (according to LW docs)
NW750_JAVA_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
NW750_JAVA_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001523262020"            # SAPEXE_700-80002573.SAR               (according to LW docs)
NW750_JAVA_KERNEL_SAPEXE_MD5="0aa8fd962c91674f7cb082d3e1d980207dc853bcce4abcb2da9a33f2b7683fdb"
NW750_JAVA_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001523902020"          # SAPEXEDB_700-80002572.SAR             (according to LW docs)
NW750_JAVA_KERNEL_SAPEXEDB_MD5="ebea79b86776d5b14ec03bcd6e473982196d2ceb7c9828e38fa8fa40fa6038e4"
NW750_JAVA_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"      # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
NW750_JAVA_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"
NW750_JAVA_KERNEL_SAPJVM="https://softwaredownloads.sap.com/file/0020000000936762022"            # SAPJVM8_89-80000202.SAR               (according to LW docs)
NW750_JAVA_KERNEL_SAPJVM_MD5="3745917ad84817d6a1239feac5a014a0c85c3e576c80e55b590fc13a429433fc"


### BW/4HANA 2.0
BW4HANA20_SAPCAR=${SAPCAR}                                                                   
BW4HANA20_SAPCAR_MD5=${SAPCAR_MD5}
BW4HANA20_SWPM=${SWPM_2_0}                                                                   
BW4HANA20_SWPM_MD5=${SWPM_2_0_MD5}
BW4HANA20_HANADB=${HANADB_LATEST}                                                              
BW4HANA20_HANADB_MD5=${HANADB_LATEST_MD5}
BW4HANA20_HANACLIENT=${HANACLIENT_LATEST}        
BW4HANA20_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
BW4HANA20_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000000365672019"         # BW4HANA200_INST_EXPORT_1.zip          (according to LW docs)
BW4HANA20_EXPORT_PART1_MD5="080a4eb72b8f969f1f7cdc577d38766888e000ac5eebec9f922a18cc626a5cf6"
BW4HANA20_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000000365682019"         # BW4HANA200_INST_EXPORT_2.zip          (according to LW docs)
BW4HANA20_EXPORT_PART2_MD5="08ace511819002d096279fe5005e8419c60ebe76fffb7ed9bb2680bf89042231"
BW4HANA20_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000000365692019"         # BW4HANA200_INST_EXPORT_3.zip          (according to LW docs)
BW4HANA20_EXPORT_PART3_MD5="9806ee7e6ca624bc931ce1944b558ae9e7eb26fbecaf5e4d67773444b62f1743"
BW4HANA20_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000000365712019"         # BW4HANA200_INST_EXPORT_4.zip          (according to LW docs)
BW4HANA20_EXPORT_PART4_MD5="33ae72916af12ff7b44db53a455b48e4c4d8e30ed5485f6a9f42cd3ca4756dc7"
BW4HANA20_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000000365742019"         # BW4HANA200_INST_EXPORT_5.zip          (according to LW docs)
BW4HANA20_EXPORT_PART5_MD5="b688ed8ff75a4ef7e9449fe5e17c1d793cab8512aabbe50cdd360a8a94f4e501"
BW4HANA20_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000000365782019"         # BW4HANA200_INST_EXPORT_6.zip          (according to LW docs)
BW4HANA20_EXPORT_PART6_MD5="7c1a7fef9a79fb1cb1af5832e2dc1f71e07824a7e1ae4ec444b7f557e949b53f"
BW4HANA20_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000000365802019"         # BW4HANA200_INST_EXPORT_7.zip          (according to LW docs)
BW4HANA20_EXPORT_PART7_MD5="e3657a358de08abc8106b21e26ea35f96b6867d9bb33da9e3116183c59a8801d"
BW4HANA20_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001632902020"        # igsexe_12-80003187.sar                (according to LW docs)
BW4HANA20_KERNEL_IGSEXE_MD5="414ab4e14e3985e03dfbc1fcc8fdfe66b0972cfcbbacf80fc4b46c93f20a557e"
BW4HANA20_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"     # igshelper_17-10010245.sar             (according to LW docs)
BW4HANA20_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
BW4HANA20_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001809672020"        # SAPEXE_300-80004393.SAR               (according to LW docs)
BW4HANA20_KERNEL_SAPEXE_MD5="f2b5d237664c3f4affa27eee72b3e34fe6daf1beeba386f67ac06be188b48fb5"
BW4HANA20_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001809622020"      # SAPEXEDB_300-80004392.SAR             (according to LW docs)
BW4HANA20_KERNEL_SAPEXEDB_MD5="5080371029f927bb0f5ea3f9f34a38a8df31ea992498140fcafe033ec0280725"
BW4HANA20_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"  # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
BW4HANA20_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"


### BW/4HANA 2021
BW4HANA21_SAPCAR=${SAPCAR}                                                                     
BW4HANA21_SAPCAR_MD5=${SAPCAR_MD5}
BW4HANA21_SWPM=${SWPM_2_0}                                                                     
BW4HANA21_SWPM_MD5=${SWPM_2_0_MD5}
BW4HANA21_HANADB=${HANADB_LATEST}                                                             
BW4HANA21_HANADB_MD5=${HANADB_LATEST_MD5}
BW4HANA21_HANACLIENT=${HANACLIENT_LATEST}
BW4HANA21_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
BW4HANA21_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001509582021"         # BW4HANA300_INST_EXPORT_1.zip          (according to LW docs)
BW4HANA21_EXPORT_PART1_MD5="eb0dde3c57a5cde657badd17b944e28e55337c19636e9a64b93b9bfa9e6f2218"
BW4HANA21_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001509592021"         # BW4HANA300_INST_EXPORT_2.zip          (according to LW docs)
BW4HANA21_EXPORT_PART2_MD5="9ce1cd9b8bde689cfb4780aebd8611a4f4a0aba648acad0eb33777d782904b17"
BW4HANA21_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001509602021"         # BW4HANA300_INST_EXPORT_3.zip          (according to LW docs)
BW4HANA21_EXPORT_PART3_MD5="15ceaa468fc350f87e4da477c1c15d9606fd1332612db096a7a8e93e6f235c3b"
BW4HANA21_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001509622021"         # BW4HANA300_INST_EXPORT_4.zip          (according to LW docs)
BW4HANA21_EXPORT_PART4_MD5="d16a144feed13068fe70e94fb73419688b21ab85e10ceef461fbac5499a7326b"
BW4HANA21_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001509632021"         # BW4HANA300_INST_EXPORT_5.zip          (according to LW docs)
BW4HANA21_EXPORT_PART5_MD5="430346f15f91209d721cafa852ec4ed28c8fa263b7ece0da66ce480fe0e06234"
BW4HANA21_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001509662021"         # BW4HANA300_INST_EXPORT_6.zip          (according to LW docs)
BW4HANA21_EXPORT_PART6_MD5="6a4dd12ecd7d3313fac30c83fa3021f6cad9f05c937927760ad64d88a2f7c6ac"
BW4HANA21_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001509692021"         # BW4HANA300_INST_EXPORT_7.zip          (according to LW docs)
BW4HANA21_EXPORT_PART7_MD5="665c4970423c9cfbed5e92a055da5018863a6bf8023284ec955988bfcf450bb2"
BW4HANA21_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001509712021"         # BW4HANA300_INST_EXPORT_8.zip          (according to LW docs)
BW4HANA21_EXPORT_PART8_MD5="e52026f914578b09ef059a75b2a1f16cedd9bae3fac83877b613ff093aede38f"
BW4HANA21_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001634982020"        # igsexe_0-70005417.sar                 (according to LW docs)
BW4HANA21_KERNEL_IGSEXE_MD5="70178c0d0b7eb0b1124310ee6e4fb102a026f8506928be41164b747dc5dff0ad"
BW4HANA21_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"     # igshelper_17-10010245.sar             (according to LW docs)
BW4HANA21_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
BW4HANA21_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001450632021"        # SAPEXE_50-80005374.SAR                (according to LW docs)
BW4HANA21_KERNEL_SAPEXE_MD5="bcb44551377b72a00a87ce6a61aa67be060574606d624dde2639d025c3c52ac3"
BW4HANA21_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001450532021"      # SAPEXEDB_50-80005373.SAR              (according to LW docs)
BW4HANA21_KERNEL_SAPEXEDB_MD5="e5559e4447c70fa1af1f5fc70aa998b79db07fd2aa7f6e72fdc2c26771aeff86"
BW4HANA21_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001542872021"  # SAPHOSTAGENT54_54-80004822.SAR        (according to LW docs)
BW4HANA21_KERNEL_SAPHOSTAGENT_MD5="5899a0934bd8d37a887d0d67de6ac0520f907a66ff7c3bc79176fff99171a878"


### S/4HANA 1909
S4HANA19_SAPCAR=${SAPCAR}                                                                   
S4HANA19_SAPCAR_MD5=${SAPCAR_MD5}
S4HANA19_SWPM=${SWPM_2_0}                                                                      
S4HANA19_SWPM_MD5=${SWPM_2_0_MD5}
S4HANA19_HANADB=${HANADB_LATEST}                                                                
S4HANA19_HANADB_MD5=${HANADB_LATEST_MD5}
S4HANA19_HANACLIENT=${HANACLIENT_LATEST}
S4HANA19_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
S4HANA19_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001632352019"          # S4CORE104_INST_EXPORT_1.zip           (according to LW docs)
S4HANA19_EXPORT_PART1_MD5="47f2355aa3a41efea260ffba9fb1d88b7716d42d337bbae7727550150ac356dc"
S4HANA19_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001632802019"          # S4CORE104_INST_EXPORT_2.zip           (according to LW docs)
S4HANA19_EXPORT_PART2_MD5="fe1ecc302a46af0f74be2f2fa135f38a7d09e1bb6482ac36b0faa5316e053d85"
S4HANA19_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001633012019"          # S4CORE104_INST_EXPORT_3.zip           (according to LW docs)
S4HANA19_EXPORT_PART3_MD5="5c22db1a220af7f2cc5d90e8d850ff528078ba6823fc85544c7d668c6a287e46"
S4HANA19_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001633032019"          # S4CORE104_INST_EXPORT_4.zip           (according to LW docs)
S4HANA19_EXPORT_PART4_MD5="e724cc5c825276aa724c8137cc888c92f438045695ab0b415cda2645a64aea95"
S4HANA19_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001633052019"          # S4CORE104_INST_EXPORT_5.zip           (according to LW docs)
S4HANA19_EXPORT_PART5_MD5="1bcf37d22909ed68a28519aa68ea92b7ed81eeb5d7be4ce4ce1c0f60909a87ab"
S4HANA19_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001633092019"          # S4CORE104_INST_EXPORT_6.zip           (according to LW docs)
S4HANA19_EXPORT_PART6_MD5="e08ff082e15e03ffc86f38cca0fe58b2807546ad7872402e94e059d90c07604b"
S4HANA19_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001633142019"          # S4CORE104_INST_EXPORT_7.zip           (according to LW docs)
S4HANA19_EXPORT_PART7_MD5="52af7674efdb544b63316fb9c9c59bd4be15ccebc224b8f0e4d505237d51a732"
S4HANA19_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001633192019"          # S4CORE104_INST_EXPORT_8.zip           (according to LW docs)
S4HANA19_EXPORT_PART8_MD5="627db4ddc37ac46034022c0abd9efd2076c0269217d2caa0736c17183efd9d8c"
S4HANA19_EXPORT_PART9="https://softwaredownloads.sap.com/file/0030000001633242019"          # S4CORE104_INST_EXPORT_9.zip           (according to LW docs)
S4HANA19_EXPORT_PART9_MD5="7f798f08ab2170dd073d94d0c847665bb14ba1b9233a9ed223becea56f72e7cc"
S4HANA19_EXPORT_PART10="https://softwaredownloads.sap.com/file/0030000001632372019"         # S4CORE104_INST_EXPORT_10.zip          (according to LW docs)
S4HANA19_EXPORT_PART10_MD5="3d2bb02443a9ca5e326b76055a6e932e702a2e3347557b6e0c5f2e6aa3f5fb67"
S4HANA19_EXPORT_PART11="https://softwaredownloads.sap.com/file/0030000001632382019"         # S4CORE104_INST_EXPORT_11.zip          (according to LW docs)
S4HANA19_EXPORT_PART11_MD5="daa5e887436d943cd95c9864b7ba0aa5fb064c02d68d435d27ae4e31bdaa42ec"
S4HANA19_EXPORT_PART12="https://softwaredownloads.sap.com/file/0030000001632402019"         # S4CORE104_INST_EXPORT_12.zip          (according to LW docs)
S4HANA19_EXPORT_PART12_MD5="1860b110884f97ad2dbfd09c8cc39dd45e20952e7ee3bfddf87b849915b597a8"
S4HANA19_EXPORT_PART13="https://softwaredownloads.sap.com/file/0030000001632442019"         # S4CORE104_INST_EXPORT_13.zip          (according to LW docs)
S4HANA19_EXPORT_PART13_MD5="82ac509bdbef4d6cbceacb926613809a7972739bbaab75345a3dfec3c1d421c1"
S4HANA19_EXPORT_PART14="https://softwaredownloads.sap.com/file/0030000001632472019"         # S4CORE104_INST_EXPORT_14.zip          (according to LW docs)
S4HANA19_EXPORT_PART14_MD5="4877c6cb6f616ef9a22ed94048025921792a8c04e54808643459b9b20fd6ab75"
S4HANA19_EXPORT_PART15="https://softwaredownloads.sap.com/file/0030000001632502019"         # S4CORE104_INST_EXPORT_15.zip          (according to LW docs)
S4HANA19_EXPORT_PART15_MD5="db377a0456151e594f57745603088316c8d91c28b7ad4a61ffa27fb368fadfa8"
S4HANA19_EXPORT_PART16="https://softwaredownloads.sap.com/file/0030000001632562019"         # S4CORE104_INST_EXPORT_16.zip          (according to LW docs)
S4HANA19_EXPORT_PART16_MD5="f6a7e1b0df2ecfcdc107b09f21d5e00cb73e64d25cfca4a92e0e123ca810e685"
S4HANA19_EXPORT_PART17="https://softwaredownloads.sap.com/file/0030000001632682019"         # S4CORE104_INST_EXPORT_17.zip          (according to LW docs)
S4HANA19_EXPORT_PART17_MD5="a85d693d10bec340473f3136a6dbe20673209a15a0154a9b3da1c185cb800171"
S4HANA19_EXPORT_PART18="https://softwaredownloads.sap.com/file/0030000001632732019"         # S4CORE104_INST_EXPORT_18.zip          (according to LW docs)
S4HANA19_EXPORT_PART18_MD5="8bc95160c003e023bfb2b122e102ff9efc384d05dd1c24d5ff88b24d9315ef4e"
S4HANA19_EXPORT_PART19="https://softwaredownloads.sap.com/file/0030000001632782019"         # S4CORE104_INST_EXPORT_19.zip          (according to LW docs)
S4HANA19_EXPORT_PART19_MD5="1f86d2428b8ad9c421241bde55d97f8e5707235c3edfea97d53723e407a8acc8"
S4HANA19_EXPORT_PART20="https://softwaredownloads.sap.com/file/0030000001632832019"         # S4CORE104_INST_EXPORT_20.zip          (according to LW docs)
S4HANA19_EXPORT_PART20_MD5="e9a1425b8dddee1cb49a8bbbffcd1569cac0857822d0b094534936b5f1eec84c"
S4HANA19_EXPORT_PART21="https://softwaredownloads.sap.com/file/0030000001632862019"         # S4CORE104_INST_EXPORT_21.zip          (according to LW docs)
S4HANA19_EXPORT_PART21_MD5="3e016dbfbe965719578e999601f57eb88112954c1f906cf65149def39732c0f9"
S4HANA19_EXPORT_PART22="https://softwaredownloads.sap.com/file/0030000001632902019"         # S4CORE104_INST_EXPORT_22.zip          (according to LW docs)
S4HANA19_EXPORT_PART22_MD5="645ea88066171ffbc8da427254f7bb45919d18610e697afc81c7ca71fff56fed"
S4HANA19_EXPORT_PART23="https://softwaredownloads.sap.com/file/0030000001632932019"         # S4CORE104_INST_EXPORT_23.zip          (according to LW docs)
S4HANA19_EXPORT_PART23_MD5="e0e69bf2f0b2e3215656a8ed94d8067f971d5264815fa2a06a9c78961b801f22"
S4HANA19_EXPORT_PART24="https://softwaredownloads.sap.com/file/0030000001632972019"         # S4CORE104_INST_EXPORT_24.zip          (according to LW docs)
S4HANA19_EXPORT_PART24_MD5="22b915225787d717e530b13b06f9af2e0c316c664b49c63cce7483216142a890"
S4HANA19_EXPORT_PART25="https://softwaredownloads.sap.com/file/0030000001633002019"         # S4CORE104_INST_EXPORT_25.zip          (according to LW docs)
S4HANA19_EXPORT_PART25_MD5="04963a19c65a5b985a8c4aaf0c31c5adaf45aa8f2252dd5037b0a723d8eac45b"
S4HANA19_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001632902020"         # igsexe_12-80003187.sar                (according to LW docs)
S4HANA19_KERNEL_IGSEXE_MD5="414ab4e14e3985e03dfbc1fcc8fdfe66b0972cfcbbacf80fc4b46c93f20a557e"
S4HANA19_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"      # igshelper_17-10010245.sar             (according to LW docs)
S4HANA19_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
S4HANA19_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001809672020"         # SAPEXE_300-80004393.SAR               (according to LW docs)
S4HANA19_KERNEL_SAPEXE_MD5="f2b5d237664c3f4affa27eee72b3e34fe6daf1beeba386f67ac06be188b48fb5"
S4HANA19_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001809622020"       # SAPEXEDB_300-80004392.SAR             (according to LW docs)
S4HANA19_KERNEL_SAPEXEDB_MD5="5080371029f927bb0f5ea3f9f34a38a8df31ea992498140fcafe033ec0280725"
S4HANA19_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"   # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
S4HANA19_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"


### S/4HANA 2020
S4HANA20_SAPCAR=${SAPCAR}                                                                    
S4HANA20_SAPCAR_MD5=${SAPCAR_MD5}
S4HANA20_SWPM=${SWPM_2_0}                                                                   
S4HANA20_SWPM_MD5=${SWPM_2_0_MD5}
S4HANA20_HANADB=${HANADB_LATEST}                                                                
S4HANA20_HANADB_MD5=${HANADB_LATEST_MD5}
S4HANA20_HANACLIENT=${HANACLIENT_LATEST}
S4HANA20_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
S4HANA20_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001666752020"          # S4CORE105_INST_EXPORT_1.zip           (according to LW docs)
S4HANA20_EXPORT_PART1_MD5="bf8ea8d901a9be19b008b20025d9120360c53277e8bc08b31ca7ff837718eadc"
S4HANA20_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001666922020"          # S4CORE105_INST_EXPORT_2.zip           (according to LW docs)
S4HANA20_EXPORT_PART2_MD5="8443085add99ad782c6d1be039ceeac1865a6a78fe448835f8af5ff06c62f116"
S4HANA20_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001667002020"          # S4CORE105_INST_EXPORT_3.zip           (according to LW docs)
S4HANA20_EXPORT_PART3_MD5="b3291c94a1981097f6a24936d99a1c5002a319acffcb0be806e54a4359075274"
S4HANA20_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001667012020"          # S4CORE105_INST_EXPORT_4.zip           (according to LW docs)
S4HANA20_EXPORT_PART4_MD5="56412f68d17920c8cffb6d1af0d39a60c73b8d47a2b572bed38eafd3e31956b1"
S4HANA20_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001667022020"          # S4CORE105_INST_EXPORT_5.zip           (according to LW docs)
S4HANA20_EXPORT_PART5_MD5="1ec1bbac65617081ab4ca20976d99d4824a2e9cd8371743059adc4add01d4180"
S4HANA20_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001667032020"          # S4CORE105_INST_EXPORT_6.zip           (according to LW docs)
S4HANA20_EXPORT_PART6_MD5="2186941d7584d21e718fe2ab2e9df92221d4322751d317dabc9131f37c7c2a2f"
S4HANA20_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001667052020"          # S4CORE105_INST_EXPORT_7.zip           (according to LW docs)
S4HANA20_EXPORT_PART7_MD5="a569ca20838ad888ec881024840c4a31db5c76ae2dbb4ba31f6e2f1ac9cd18a8"
S4HANA20_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001667062020"          # S4CORE105_INST_EXPORT_8.zip           (according to LW docs)
S4HANA20_EXPORT_PART8_MD5="b94fab3ede5a111b1709af65352c835d531407fb09e12a146fdc97a61786b592"
S4HANA20_EXPORT_PART9="https://softwaredownloads.sap.com/file/0030000001667072020"          # S4CORE105_INST_EXPORT_9.zip           (according to LW docs)
S4HANA20_EXPORT_PART9_MD5="14c2982a43f9f61cd2446fff6474e0368bcc27799883c6a06768783d06698322"
S4HANA20_EXPORT_PART10="https://softwaredownloads.sap.com/file/0030000001666762020"         # S4CORE105_INST_EXPORT_10.zip          (according to LW docs)
S4HANA20_EXPORT_PART10_MD5="53223fe52caae836b0a63a673e9d8f5e9a3b767d1139c9380a56030a652a13fa"
S4HANA20_EXPORT_PART11="https://softwaredownloads.sap.com/file/0030000001666772020"         # S4CORE105_INST_EXPORT_11.zip          (according to LW docs)
S4HANA20_EXPORT_PART11_MD5="41a07b3a213ddf3a2ce2ebcdf971e325ee2c9c725495c0908bd5772f43efd5d9"
S4HANA20_EXPORT_PART12="https://softwaredownloads.sap.com/file/0030000001666782020"         # S4CORE105_INST_EXPORT_12.zip          (according to LW docs)
S4HANA20_EXPORT_PART12_MD5="c8dc600b858ffa32d99e4e1aa18b632674c55e2cf1d2d38e88ac968b78ead2ab"
S4HANA20_EXPORT_PART13="https://softwaredownloads.sap.com/file/0030000001666802020"         # S4CORE105_INST_EXPORT_13.zip          (according to LW docs)
S4HANA20_EXPORT_PART13_MD5="005012e0736bd8ee7f5862c23d5be3d9172d7a7efac6c50553561806ecc8442b"
S4HANA20_EXPORT_PART14="https://softwaredownloads.sap.com/file/0030000001666842020"         # S4CORE105_INST_EXPORT_14.zip          (according to LW docs)
S4HANA20_EXPORT_PART14_MD5="d1b012b1694c55aee5b1e158d11d9d7831742affda319749bbd71ebc5db16c04"
S4HANA20_EXPORT_PART15="https://softwaredownloads.sap.com/file/0030000001666862020"         # S4CORE105_INST_EXPORT_15.zip          (according to LW docs)
S4HANA20_EXPORT_PART15_MD5="a9925856644cec2404956e17218dc0d7555cbcb8c402d007faa7c0beac1b0f8a"
S4HANA20_EXPORT_PART16="https://softwaredownloads.sap.com/file/0030000001666872020"         # S4CORE105_INST_EXPORT_16.zip          (according to LW docs)
S4HANA20_EXPORT_PART16_MD5="473282155d7e5a9d86312d4f95b1df350d952b32ffd4494b29b1228746484d02"
S4HANA20_EXPORT_PART17="https://softwaredownloads.sap.com/file/0030000001666882020"         # S4CORE105_INST_EXPORT_17.zip          (according to LW docs)
S4HANA20_EXPORT_PART17_MD5="b00799a132ae3b6f0798791c0a8389090ee6fe64895898b2f9bf37a7881e1836"
S4HANA20_EXPORT_PART18="https://softwaredownloads.sap.com/file/0030000001666892020"         # S4CORE105_INST_EXPORT_18.zip          (according to LW docs)
S4HANA20_EXPORT_PART18_MD5="23552a7bf21e0b92765e9778b6f081e11680a58c4d7d63c8598ee95d5879a9d1"
S4HANA20_EXPORT_PART19="https://softwaredownloads.sap.com/file/0030000001666912020"         # S4CORE105_INST_EXPORT_19.zip          (according to LW docs)
S4HANA20_EXPORT_PART19_MD5="9d60e53217e0566b05fe06dc7dfde016d2f8f259c73fef6064b5a4f1772a24f8"
S4HANA20_EXPORT_PART20="https://softwaredownloads.sap.com/file/0030000001666932020"         # S4CORE105_INST_EXPORT_20.zip          (according to LW docs)
S4HANA20_EXPORT_PART20_MD5="fc6eae3d201d3b839deab2f7196976b40408bd24bf5ea85183235790e483e8cc"
S4HANA20_EXPORT_PART21="https://softwaredownloads.sap.com/file/0030000001666942020"         # S4CORE105_INST_EXPORT_21.zip          (according to LW docs)
S4HANA20_EXPORT_PART21_MD5="f76a740da5218d8445ef028b501fff8486b4eb315367f70dba93940f4bfdf6e5"
S4HANA20_EXPORT_PART22="https://softwaredownloads.sap.com/file/0030000001666952020"         # S4CORE105_INST_EXPORT_22.zip          (according to LW docs)
S4HANA20_EXPORT_PART22_MD5="f5b2af2bca509a8cfa1738e23490ef646a657abffd7c94863abd445057f60ad8"
S4HANA20_EXPORT_PART23="https://softwaredownloads.sap.com/file/0030000001666982020"         # S4CORE105_INST_EXPORT_23.zip          (according to LW docs)
S4HANA20_EXPORT_PART23_MD5="db4f4b1e52665fbf9b8a98ee36c3f702e3aaec3cd9278f5ad6b7d777693a7810"
S4HANA20_EXPORT_PART24="https://softwaredownloads.sap.com/file/0030000001666992020"         # S4CORE105_INST_EXPORT_24.zip          (according to LW docs)
S4HANA20_EXPORT_PART24_MD5="7d78b729a8c5ff021e943a2decfb4c8c047458b1848939e50edf37c6915fc46b"
S4HANA20_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001634982020"         # igsexe_0-70005417.sar                 (according to LW docs)
S4HANA20_KERNEL_IGSEXE_MD5="70178c0d0b7eb0b1124310ee6e4fb102a026f8506928be41164b747dc5dff0ad"
S4HANA20_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"      # igshelper_17-10010245.sar             (according to LW docs)
S4HANA20_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
S4HANA20_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001676002020"         # SAPEXE_15-70005283.SAR                (according to LW docs)
S4HANA20_KERNEL_SAPEXE_MD5="8e818cd33283666994c75064cc69d2d72cb6cd9acd873c41ff104a8d0cdc04e9"
S4HANA20_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001675852020"       # SAPEXEDB_50-80005373.SAR              (according to LW docs)
S4HANA20_KERNEL_SAPEXEDB_MD5="525a3a320e64a560eff08ebc4fbbbaef8109f75b80ce857b5f5b87cc10806c68"
S4HANA20_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"   # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
S4HANA20_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"


### S/4HANA 2021
S4HANA21_SAPCAR=${SAPCAR}                                                                    
S4HANA21_SAPCAR_MD5=${SAPCAR_MD5}
S4HANA21_SWPM=${SWPM_2_0}                                                                  
S4HANA21_SWPM_MD5=${SWPM_2_0_MD5}
S4HANA21_HANADB=${HANADB_LATEST}                                                               
S4HANA21_HANADB_MD5=${HANADB_LATEST_MD5}
S4HANA21_HANACLIENT=${HANACLIENT_LATEST}            
S4HANA21_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
S4HANA21_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001440322021"          # S4CORE106_INST_EXPORT_1.exe                    (according to LW docs)
S4HANA21_EXPORT_PART1_MD5="1b0701e9360078a7ac3f58c46b81d84ccdb35147732dc1b87efa54bc6d49cac4"
S4HANA21_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001440482021"          # S4CORE106_INST_EXPORT_2.rar                    (according to LW docs)
S4HANA21_EXPORT_PART2_MD5="f9abb08182c45261a29eda3dd982ff739f8150da4f5f218197191e6e14d2bbed"
S4HANA21_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001440602021"          # S4CORE106_INST_EXPORT_3.rar                    (according to LW docs)
S4HANA21_EXPORT_PART3_MD5="a2f3dfbb0fe22d5bf8cf2c05297f71308ab3019a24cc0b99be439de405737b1c"
S4HANA21_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001440612021"          # S4CORE106_INST_EXPORT_4.rar                    (according to LW docs)
S4HANA21_EXPORT_PART4_MD5="3919f528a190f3d3c4e07809463ff559828b5d5aa99d9b132ac0a5a6c17aa69d"
S4HANA21_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001440622021"          # S4CORE106_INST_EXPORT_5.rar                    (according to LW docs)
S4HANA21_EXPORT_PART5_MD5="6ebe1a2086fc84417297ea085f8ade1c7fe92003abe827a73a5984a42fb756ff"
S4HANA21_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001440632021"          # S4CORE106_INST_EXPORT_6.rar                    (according to LW docs)
S4HANA21_EXPORT_PART6_MD5="1669c755f541b146fef32329a19fc09d5ea19d3232a75392db80c3a956df4a67"
S4HANA21_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001440642021"          # S4CORE106_INST_EXPORT_7.rar                    (according to LW docs)
S4HANA21_EXPORT_PART7_MD5="8f1d6726d9e1fdae0087626ecbc19734b331a09ab02289449d23a84171c1bc57"
S4HANA21_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001440662021"          # S4CORE106_INST_EXPORT_8.rar                    (according to LW docs)
S4HANA21_EXPORT_PART8_MD5="4f8a3ddd87c905660e962e21dcc6d3860e7af19b2422265c469a733d0150aff4"
S4HANA21_EXPORT_PART9="https://softwaredownloads.sap.com/file/0030000001440672021"          # S4CORE106_INST_EXPORT_9.rar                    (according to LW docs)
S4HANA21_EXPORT_PART9_MD5="436299f393faef7845694b885a1f4a66e921eaa888db31981e5dea4f9737d720"
S4HANA21_EXPORT_PART10="https://softwaredownloads.sap.com/file/0030000001440332021"         # S4CORE106_INST_EXPORT_10.rar                   (according to LW docs)
S4HANA21_EXPORT_PART10_MD5="9d35b198c48abec7ee2b3b312b26e6775d7a63c5fbbe559ef8815d402d7b8abb"
S4HANA21_EXPORT_PART11="https://softwaredownloads.sap.com/file/0030000001440352021"         # S4CORE106_INST_EXPORT_11.rar                   (according to LW docs)
S4HANA21_EXPORT_PART11_MD5="f78f4a94771812b4ce7e9d3b46090786ad7b8efe6e33008b8aaf5da59f254424"
S4HANA21_EXPORT_PART12="https://softwaredownloads.sap.com/file/0030000001440382021"         # S4CORE106_INST_EXPORT_12.rar                   (according to LW docs)
S4HANA21_EXPORT_PART12_MD5="5573a086cdaab489c83298f715aab1e8f3ebdc91fe95cf8afc6a33c3c0aee97d"
S4HANA21_EXPORT_PART13="https://softwaredownloads.sap.com/file/0030000001440392021"         # S4CORE106_INST_EXPORT_13.rar                   (according to LW docs)
S4HANA21_EXPORT_PART13_MD5="c54f2c931d78890a90525d59be39132090912856925863eb3bc23e4bc8ab2d7f"
S4HANA21_EXPORT_PART14="https://softwaredownloads.sap.com/file/0030000001440402021"         # S4CORE106_INST_EXPORT_14.rar                   (according to LW docs)
S4HANA21_EXPORT_PART14_MD5="93f0551134e6b3b36b739656c59c1c41537555b2017295002e4c79df63e388c1"
S4HANA21_EXPORT_PART15="https://softwaredownloads.sap.com/file/0030000001440412021"         # S4CORE106_INST_EXPORT_15.rar                   (according to LW docs)
S4HANA21_EXPORT_PART15_MD5="40c5daf1a78f66439d3c960e2fc42561461aa2872fcc28311db7d9adeb73604d"
S4HANA21_EXPORT_PART16="https://softwaredownloads.sap.com/file/0030000001440422021"         # S4CORE106_INST_EXPORT_16.rar                   (according to LW docs)
S4HANA21_EXPORT_PART16_MD5="5ce92411168a1d82aeaa2242ccec2b1b1ea8d90234fa168c21ab4cc36be8877f"
S4HANA21_EXPORT_PART17="https://softwaredownloads.sap.com/file/0030000001440442021"         # S4CORE106_INST_EXPORT_17.rar                   (according to LW docs)
S4HANA21_EXPORT_PART17_MD5="9fd961527685a332cc1d91e7110654a1629b12398548b5ac2671df2088b9eb09"
S4HANA21_EXPORT_PART18="https://softwaredownloads.sap.com/file/0030000001440452021"         # S4CORE106_INST_EXPORT_18.rar                   (according to LW docs)
S4HANA21_EXPORT_PART18_MD5="339fc3b6ae55b369ffabbc9d001bf331d831fde7b399ad39bac942b80719102d"
S4HANA21_EXPORT_PART19="https://softwaredownloads.sap.com/file/0030000001440472021"         # S4CORE106_INST_EXPORT_19.rar                   (according to LW docs)
S4HANA21_EXPORT_PART19_MD5="d2a6628551366e2af1524490381988cfa9c2f6c368458963dc5c45fbd9c4b33d"
S4HANA21_EXPORT_PART20="https://softwaredownloads.sap.com/file/0030000001440492021"         # S4CORE106_INST_EXPORT_20.rar                   (according to LW docs)
S4HANA21_EXPORT_PART20_MD5="0fbc882160971154e2831394d8c39c1db775872d0ed016ad77186bdbe6270710"
S4HANA21_EXPORT_PART21="https://softwaredownloads.sap.com/file/0030000001440502021"         # S4CORE106_INST_EXPORT_21.rar                   (according to LW docs)
S4HANA21_EXPORT_PART21_MD5="0c98936c820d488eb2c1a736a7d6eafc205d8dfd7907bf52114b38a62a612f4c"
S4HANA21_EXPORT_PART22="https://softwaredownloads.sap.com/file/0030000001440512021"         # S4CORE106_INST_EXPORT_22.rar                   (according to LW docs)
S4HANA21_EXPORT_PART22_MD5="30ed829b64f20f1758278ec47a8b577919af68bc6517dbba287e19cce7584e25"
S4HANA21_EXPORT_PART23="https://softwaredownloads.sap.com/file/0030000001440532021"         # S4CORE106_INST_EXPORT_23.rar                   (according to LW docs)
S4HANA21_EXPORT_PART23_MD5="44ec50e90470da11abfeb019d830eeaacd22d9069566c15a67f65115ac0b990a"
S4HANA21_EXPORT_PART24="https://softwaredownloads.sap.com/file/0030000001440542021"         # S4CORE106_INST_EXPORT_24.rar                   (according to LW docs)
S4HANA21_EXPORT_PART24_MD5="8c194ed2414583f750fc440f21d3701b4f8914e225fa4931b577b222a3919323"
S4HANA21_EXPORT_PART25="https://softwaredownloads.sap.com/file/0030000001440562021"         # S4CORE106_INST_EXPORT_25.rar                   (according to LW docs)
S4HANA21_EXPORT_PART25_MD5="09b66e5513577789288586529c892cd5276ee49d5adf3e4b97bfabaab13430e9"
S4HANA21_EXPORT_PART26="https://softwaredownloads.sap.com/file/0030000001440572021"         # S4CORE106_INST_EXPORT_26.rar                   (according to LW docs)
S4HANA21_EXPORT_PART26_MD5="7d27fcd9ff327bbefdf8acb4748753cbc778f1d0ba5cda3ca224aef535420c80"
S4HANA21_EXPORT_PART27="https://softwaredownloads.sap.com/file/0030000001440582021"         # S4CORE106_INST_EXPORT_27.rar                   (according to LW docs)
S4HANA21_EXPORT_PART27_MD5="d6a6fcbff9e5215f7c10beb0ed1006aa0da9054c671e86bbcd9342abb60fff22"
S4HANA21_EXPORT_PART28="https://softwaredownloads.sap.com/file/0030000001440592021"         # S4CORE106_INST_EXPORT_28.rar                   (according to LW docs)
S4HANA21_EXPORT_PART28_MD5="2926277d7aa678403c4f88d42b0f67a259ff689f11cbc13a64e5c2605038d7ac"
S4HANA21_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001634982020"         # igsexe_0-70005417.sar                 (according to LW docs)
S4HANA21_KERNEL_IGSEXE_MD5="70178c0d0b7eb0b1124310ee6e4fb102a026f8506928be41164b747dc5dff0ad"
S4HANA21_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"      # igshelper_17-10010245.sar             (according to LW docs)
S4HANA21_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
S4HANA21_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001450632021"         # SAPEXE_50-80005374.SAR                (according to LW docs)
S4HANA21_KERNEL_SAPEXE_MD5="bcb44551377b72a00a87ce6a61aa67be060574606d624dde2639d025c3c52ac3"
S4HANA21_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001450532021"       # SAPEXEDB_50-80005373.SAR              (according to LW docs)
S4HANA21_KERNEL_SAPEXEDB_MD5="e5559e4447c70fa1af1f5fc70aa998b79db07fd2aa7f6e72fdc2c26771aeff86"
S4HANA21_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001542872021"   # SAPHOSTAGENT54_54-80004822.SAR        (according to LW docs)
S4HANA21_KERNEL_SAPHOSTAGENT_MD5="5899a0934bd8d37a887d0d67de6ac0520f907a66ff7c3bc79176fff99171a878"


### S/4HANA 2022
S4HANA22_SAPCAR=${SAPCAR}                                                                     
S4HANA22_SAPCAR_MD5=${SAPCAR_MD5}
S4HANA22_SWPM=${SWPM_2_0}                                                                     
S4HANA22_SWPM_MD5=${SWPM_2_0_MD5}
S4HANA22_HANADB=${HANADB_LATEST}                                                               
S4HANA22_HANADB_MD5=${HANADB_LATEST_MD5}
S4HANA22_HANACLIENT=${HANACLIENT_LATEST}            
S4HANA22_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
S4HANA22_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001314832022"          # S4CORE107_INST_EXPORT_1.zip           (according to LW docs)
S4HANA22_EXPORT_PART1_MD5="5aad867d61cf19cb5b6a4b28c1b531a90dfd783fc974f9fb9a11afab2f68b16b"
S4HANA22_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001314982022"          # S4CORE107_INST_EXPORT_2.rar           (according to LW docs)
S4HANA22_EXPORT_PART2_MD5="d9fc0f8ff388e0efad47f6ded3c6ac353314d2fbb03ed3cf775fd30a69c129aa"
S4HANA22_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001315202022"          # S4CORE107_INST_EXPORT_3.rar           (according to LW docs)
S4HANA22_EXPORT_PART3_MD5="b9e423890536c27dfc5398fe8691a77848bd9d13797635ccfc344ec627dd2e24"
S4HANA22_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001315222022"          # S4CORE107_INST_EXPORT_4.rar           (according to LW docs)
S4HANA22_EXPORT_PART4_MD5="9ba50e9cceb6cff8e343d716caab8866a5529579ab642b8c7354259cf80a0767"
S4HANA22_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001315232022"          # S4CORE107_INST_EXPORT_5.rar           (according to LW docs)
S4HANA22_EXPORT_PART5_MD5="3341bcaef84519ef5aefc077296935e15f1ec6167cc076238183de3c81dcb8ae"
S4HANA22_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001315252022"          # S4CORE107_INST_EXPORT_6.rar           (according to LW docs)
S4HANA22_EXPORT_PART6_MD5="da705d7e9cd81e7e9d40b967768e6352675f843389801ea94b4939f223d0524f"
S4HANA22_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001315292022"          # S4CORE107_INST_EXPORT_7.rar           (according to LW docs)
S4HANA22_EXPORT_PART7_MD5="86b72a759114c99d99f92d9b5b49a38c340ed1cdbdda89713c4af3194eadd961"
S4HANA22_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001315312022"          # S4CORE107_INST_EXPORT_8.rar           (according to LW docs)
S4HANA22_EXPORT_PART8_MD5="ae563c913d70f702af7ef27f9a8c4664ee4796815e0c4754499eb174534649e0"
S4HANA22_EXPORT_PART9="https://softwaredownloads.sap.com/file/0030000001326492022"          # S4CORE107_INST_EXPORT_9.rar           (according to LW docs)
S4HANA22_EXPORT_PART9_MD5="c4bd746054e633be73ff2cb910bfecd68ac7c0a5016c674c7b3111df5a728ac7"
S4HANA22_EXPORT_PART10="https://softwaredownloads.sap.com/file/0030000001314842022"         # S4CORE107_INST_EXPORT_10.rar          (according to LW docs)
S4HANA22_EXPORT_PART10_MD5="f92ae9350955df3662ac4bb6d1a1d86fb0d91de5e694cd1420de31f84a01c103"
S4HANA22_EXPORT_PART11="https://softwaredownloads.sap.com/file/0030000001314852022"         # S4CORE107_INST_EXPORT_11.rar          (according to LW docs)
S4HANA22_EXPORT_PART11_MD5="041b1520b2894c434932e17202871b1f82cf0748bb6205c17c0b84c8f33bd8d6"
S4HANA22_EXPORT_PART12="https://softwaredownloads.sap.com/file/0030000001314862022"         # S4CORE107_INST_EXPORT_12.rar          (according to LW docs)
S4HANA22_EXPORT_PART12_MD5="c6275415035b1fe0deea3eff4e23357fd7eca90c094741907805281a8e18628f"
S4HANA22_EXPORT_PART13="https://softwaredownloads.sap.com/file/0030000001314882022"         # S4CORE107_INST_EXPORT_13.rar          (according to LW docs)
S4HANA22_EXPORT_PART13_MD5="2e8f02a639e810e5b688dce7a1e3511e4358e1ccfe020f752f0588876a3bb462"
S4HANA22_EXPORT_PART14="https://softwaredownloads.sap.com/file/0030000001314892022"         # S4CORE107_INST_EXPORT_14.rar          (according to LW docs)
S4HANA22_EXPORT_PART14_MD5="b016046dc9b4fc3a3f0cee50c36c9110d93715da3e451dbf2d40599d36b4ae11"
S4HANA22_EXPORT_PART15="https://softwaredownloads.sap.com/file/0030000001314902022"         # S4CORE107_INST_EXPORT_15.rar          (according to LW docs)
S4HANA22_EXPORT_PART15_MD5="3af1414635b29d0c1d82a8d7425f1ad44858f334c4ac425029aa8972691111c7"
S4HANA22_EXPORT_PART16="https://softwaredownloads.sap.com/file/0030000001314912022"         # S4CORE107_INST_EXPORT_16.rar          (according to LW docs)
S4HANA22_EXPORT_PART16_MD5="dad2dc88e6a329f039227cdf48b9985d09dd2263f6c9f3904fc9fccee07787c7"
S4HANA22_EXPORT_PART17="https://softwaredownloads.sap.com/file/0030000001314932022"         # S4CORE107_INST_EXPORT_17.rar          (according to LW docs)
S4HANA22_EXPORT_PART17_MD5="fd87ebfe1196159eca3a53b4c0ffa48912602b3e5db6f17f7b091755bfca0ffc"
S4HANA22_EXPORT_PART18="https://softwaredownloads.sap.com/file/0030000001314952022"         # S4CORE107_INST_EXPORT_18.rar          (according to LW docs)
S4HANA22_EXPORT_PART18_MD5="9ab7634901b1357f45c7677f16f6e9c51ba4c0b69cdddc8ff0605ac8e1e81fb1"
S4HANA22_EXPORT_PART19="https://softwaredownloads.sap.com/file/0030000001314962022"         # S4CORE107_INST_EXPORT_19.rar          (according to LW docs)
S4HANA22_EXPORT_PART19_MD5="9889c7185bc649370067bff6aa8fc9584bc927e6252a1b359f6bb8abb59b4365"
S4HANA22_EXPORT_PART20="https://softwaredownloads.sap.com/file/0030000001315022022"         # S4CORE107_INST_EXPORT_20.rar          (according to LW docs)
S4HANA22_EXPORT_PART20_MD5="53434047e264c8e119cdf5656e6e09895b22d2610ba4c27a55922671e60faf1d"
S4HANA22_EXPORT_PART21="https://softwaredownloads.sap.com/file/0030000001315042022"         # S4CORE107_INST_EXPORT_21.rar          (according to LW docs)
S4HANA22_EXPORT_PART21_MD5="7eb5e78fb9ffe75ffde35a2d64abbbdb2022bca0ca87dd8985419652c0e2439f"
S4HANA22_EXPORT_PART22="https://softwaredownloads.sap.com/file/0030000001315052022"         # S4CORE107_INST_EXPORT_22.rar          (according to LW docs)
S4HANA22_EXPORT_PART22_MD5="d8e1a9539db3a78b66989d99a0bf65d6e7381318a284e901b9a2e02536ce92c9"
S4HANA22_EXPORT_PART23="https://softwaredownloads.sap.com/file/0030000001315062022"         # S4CORE107_INST_EXPORT_23.rar          (according to LW docs)
S4HANA22_EXPORT_PART23_MD5="54a4e6a6b50ac4a7de3a1bc37210f6051707032c9e8618ab2c52c7cd38755d02"
S4HANA22_EXPORT_PART24="https://softwaredownloads.sap.com/file/0030000001315072022"         # S4CORE107_INST_EXPORT_24.rar          (according to LW docs)
S4HANA22_EXPORT_PART24_MD5="a30de08c368b0c0a0ed621ecd59cbd98877c82b4656566d51c0da831476f766c"
S4HANA22_EXPORT_PART25="https://softwaredownloads.sap.com/file/0030000001315102022"         # S4CORE107_INST_EXPORT_25.rar          (according to LW docs)
S4HANA22_EXPORT_PART25_MD5="82fe9b2dca00fde5efe9e190009a2f3462ecf31f9a76d958bf778f2216173ab2"
S4HANA22_EXPORT_PART26="https://softwaredownloads.sap.com/file/0030000001315142022"         # S4CORE107_INST_EXPORT_26.rar          (according to LW docs)
S4HANA22_EXPORT_PART26_MD5="af6e71648328d6d1926ef99279a7f23a842a6aeda19e3840ebd8d76b47754193"
S4HANA22_EXPORT_PART27="https://softwaredownloads.sap.com/file/0030000001315152022"         # S4CORE107_INST_EXPORT_27.rar          (according to LW docs)
S4HANA22_EXPORT_PART27_MD5="9b6089c57bdfef0a2c2d97b2a8d12ffec7712be96b981dc33a0dee7a957800bb"
S4HANA22_EXPORT_PART28="https://softwaredownloads.sap.com/file/0030000001315162022"         # S4CORE107_INST_EXPORT_28.rar          (according to LW docs)
S4HANA22_EXPORT_PART28_MD5="007db0d5d8e11c567f738e52cfacedd61f3336bca0cc7db69f8f8f73fa0ab4dc"
S4HANA22_EXPORT_PART29="https://softwaredownloads.sap.com/file/0030000001315192022"         # S4CORE107_INST_EXPORT_29.rar          (according to LW docs)
S4HANA22_EXPORT_PART29_MD5="4d9e40c334208aef81c3f16a2fe2f2619956ffcae61bef27f5a85c9d2afe6a7b"
S4HANA22_EXPORT_PART30="https://softwaredownloads.sap.com/file/0030000001315332022"         # S4CORE107_INST_EXPORT_30.rar          (according to LW docs)
S4HANA22_EXPORT_PART30_MD5="5fa413b55ea5ae113a3c0914488c4035aacedba8fbe57900cdc6f5eb1c8f9b3f"
S4HANA22_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001634982020"         # igsexe_0-70005417.sar                 (according to LW docs)
S4HANA22_KERNEL_IGSEXE_MD5="70178c0d0b7eb0b1124310ee6e4fb102a026f8506928be41164b747dc5dff0ad"
S4HANA22_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"      # igshelper_17-10010245.sar             (according to LW docs)
S4HANA22_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
S4HANA22_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001628242022"         # SAPEXE_66-70006642.SAR                (according to LW docs)
S4HANA22_KERNEL_SAPEXE_MD5="de7c006e45bbdec8f5ba970f6737d3515873cef32d69bf9ad63dc291bedc7690"
S4HANA22_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001628232022"       # SAPEXEDB_66-70006641.SAR              (according to LW docs)
S4HANA22_KERNEL_SAPEXEDB_MD5="35a28a8a1d6413191b41e7dd1f60f0be9fb28777f17fa96fa0f7fd383e742479"
S4HANA22_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001542872021"   # SAPHOSTAGENT54_54-80004822.SAR        (according to LW docs)
S4HANA22_KERNEL_SAPHOSTAGENT_MD5="5899a0934bd8d37a887d0d67de6ac0520f907a66ff7c3bc79176fff99171a878"


### S/4HANA FOUNDATIONS 2021
S4HANA21_FOUNDATIONS_SAPCAR=${SAPCAR}                                                                    
S4HANA21_FOUNDATIONS_SAPCAR_MD5=${SAPCAR_MD5}
S4HANA21_FOUNDATIONS_SWPM=${SWPM_2_0}                                                                     
S4HANA21_FOUNDATIONS_SWPM_MD5=${SWPM_2_0_MD5}
S4HANA21_FOUNDATIONS_HANADB=${HANADB_LATEST}                                                               
S4HANA21_FOUNDATIONS_HANADB_MD5=${HANADB_LATEST_MD5}
S4HANA21_FOUNDATIONS_HANACLIENT=${HANACLIENT_LATEST} 
S4HANA21_FOUNDATIONS_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5} 
S4HANA21_FOUNDATIONS_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001438792021"         # S4FND106_INST_EXPORT_1.zip                   (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART1_MD5="aadb3c749e07757af51bd2644b1bf9732d00e07b08f25ab6ebe8e51863a0c379"
S4HANA21_FOUNDATIONS_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001438802021"         # S4FND106_INST_EXPORT_2.zip                   (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART2_MD5="9e3c847b54f7a9d4b2caa2b45b2400406bbad76e52867310231818d0371a3580"
S4HANA21_FOUNDATIONS_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001438812021"         # S4FND106_INST_EXPORT_3.zip                   (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART3_MD5="c7f12dc6bbf694e41eccc1ec57a6ff3887f671a3786736dafb6197d29ecbf406"
S4HANA21_FOUNDATIONS_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001438822021"         # S4FND106_INST_EXPORT_4.zip                  (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART4_MD5="541e4d37588d96d3b0eb2b50fb041c48e235cdd9c9749631a69c40ebcbd2081c"
S4HANA21_FOUNDATIONS_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001438832021"         # S4FND106_INST_EXPORT_5.zip                   (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART5_MD5="a2fa4100ee2cedee00065e47f7fd679bb5b409ec0751aa75be2f57d4d4b51662"
S4HANA21_FOUNDATIONS_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001438862021"         # S4FND106_INST_EXPORT_6.zip                  (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART6_MD5="bc641f4a6fdadbb51df4b48cdeb38900860b9c2cada0e6ff10a7291369dd6faf"
S4HANA21_FOUNDATIONS_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001438872021"         # S4FND106_INST_EXPORT_7.zip                  (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART7_MD5="efaee433f1877b81206c652d8abd63692fef8df0366527dcf8595004055ef763"
S4HANA21_FOUNDATIONS_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001438882021"         # S4FND106_INST_EXPORT_8.zip                   (according to LW docs)
S4HANA21_FOUNDATIONS_EXPORT_PART8_MD5="6d63f5e66ba7a2e4fcdfce4a4f55345718c282854821877d7b54026c271377c6"
S4HANA21_FOUNDATIONS_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001634982020"         # igsexe_0-70005417.sar                 (according to LW docs)
S4HANA21_FOUNDATIONS_KERNEL_IGSEXE_MD5="70178c0d0b7eb0b1124310ee6e4fb102a026f8506928be41164b747dc5dff0ad"
S4HANA21_FOUNDATIONS_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"      # igshelper_17-10010245.sar             (according to LW docs)
S4HANA21_FOUNDATIONS_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
S4HANA21_FOUNDATIONS_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001628242022"         # SAPEXE_66-70006642.SAR                (according to LW docs)
S4HANA21_FOUNDATIONS_KERNEL_SAPEXE_MD5="de7c006e45bbdec8f5ba970f6737d3515873cef32d69bf9ad63dc291bedc7690"
S4HANA21_FOUNDATIONS_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001628232022"       # SAPEXEDB_66-70006641.SAR              (according to LW docs)
S4HANA21_FOUNDATIONS_KERNEL_SAPEXEDB_MD5="35a28a8a1d6413191b41e7dd1f60f0be9fb28777f17fa96fa0f7fd383e742479"
S4HANA21_FOUNDATIONS_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001542872021"   # SAPHOSTAGENT54_54-80004822.SAR        (according to LW docs)
S4HANA21_FOUNDATIONS_KERNEL_SAPHOSTAGENT_MD5="5899a0934bd8d37a887d0d67de6ac0520f907a66ff7c3bc79176fff99171a878"


### S/4HANA FOUNDATIONS 2022
S4HANA22_FOUNDATIONS_SAPCAR=${SAPCAR}                                                                 
S4HANA22_FOUNDATIONS_SAPCAR_MD5=${SAPCAR_MD5}
S4HANA22_FOUNDATIONS_SWPM=${SWPM_2_0}                                                                   
S4HANA22_FOUNDATIONS_SWPM_MD5=${SWPM_2_0_MD5}
S4HANA22_FOUNDATIONS_HANADB=${HANADB_LATEST}                                                             
S4HANA22_FOUNDATIONS_HANADB_MD5=${HANADB_LATEST_MD5}
S4HANA22_FOUNDATIONS_HANACLIENT=${HANACLIENT_LATEST} 
S4HANA22_FOUNDATIONS_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5} 
S4HANA22_FOUNDATIONS_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000001310152022"         # S4FND107_INST_EXPORT_1.zip                   (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART1_MD5="56a6edd18c7ee766c9c126b7b98de24bcba4b488f2aed10d060732be8ce8bd7b"
S4HANA22_FOUNDATIONS_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000001310162022"         # S4FND107_INST_EXPORT_2.zip                   (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART2_MD5="0217868e4a1299c21cb59909a398219878f061b434cb65ab03ca4c7a0056f17e"
S4HANA22_FOUNDATIONS_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000001310182022"         # S4FND107_INST_EXPORT_3.zip                   (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART3_MD5="38c7fea39c8579f98e3217e42ba87a2c44181209d67916dd427596e8a565123a"
S4HANA22_FOUNDATIONS_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000001310192022"         # S4FND107_INST_EXPORT_4.zip                  (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART4_MD5="03cc360fb8bc515307f758790858930a09dfd8262ab4da0ae31f61d7139ff730"
S4HANA22_FOUNDATIONS_EXPORT_PART5="https://softwaredownloads.sap.com/file/0030000001310212022"         # S4FND107_INST_EXPORT_5.zip                   (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART5_MD5="b946c382cf40625f44f4f17b594f2050f6525a83946ac13d9b4cfea0e47b91eb"
S4HANA22_FOUNDATIONS_EXPORT_PART6="https://softwaredownloads.sap.com/file/0030000001310222022"         # S4FND107_INST_EXPORT_6.zip                  (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART6_MD5="4ca7c8cfc184e518daf7c01482ea7b20ae5b91bbd1f34e1b8a2bf5c80a13b87b"
S4HANA22_FOUNDATIONS_EXPORT_PART7="https://softwaredownloads.sap.com/file/0030000001310272022"         # S4FND107_INST_EXPORT_7.zip                  (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART7_MD5="12f110dbe70c1bc50276d5a20715a93aef2a66749e17667535380919794c4b90"
S4HANA22_FOUNDATIONS_EXPORT_PART8="https://softwaredownloads.sap.com/file/0030000001310292022"         # S4FND107_INST_EXPORT_8.zip                   (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART8_MD5="fe60f51145f8e148bece4763b096aeea5af21b50840d761ee4ee717e3347342c"
S4HANA22_FOUNDATIONS_EXPORT_PART9="https://softwaredownloads.sap.com/file/0030000001310302022"         # S4FND107_INST_EXPORT_9.zip                   (according to LW docs)
S4HANA22_FOUNDATIONS_EXPORT_PART9_MD5="08d38e9fac481f2f920c27ace1248501aeed4c96e33f2e1b0bcde87b1298738f"
S4HANA22_FOUNDATIONS_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001634982020"         # igsexe_0-70005417.sar                 (according to LW docs)
S4HANA22_FOUNDATIONS_KERNEL_IGSEXE_MD5="70178c0d0b7eb0b1124310ee6e4fb102a026f8506928be41164b747dc5dff0ad"
S4HANA22_FOUNDATIONS_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"      # igshelper_17-10010245.sar             (according to LW docs)
S4HANA22_FOUNDATIONS_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
S4HANA22_FOUNDATIONS_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001628242022"         # SAPEXE_66-70006642.SAR                (according to LW docs)
S4HANA22_FOUNDATIONS_KERNEL_SAPEXE_MD5="de7c006e45bbdec8f5ba970f6737d3515873cef32d69bf9ad63dc291bedc7690"
S4HANA22_FOUNDATIONS_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001628232022"       # SAPEXEDB_66-70006641.SAR              (according to LW docs)
S4HANA22_FOUNDATIONS_KERNEL_SAPEXEDB_MD5="35a28a8a1d6413191b41e7dd1f60f0be9fb28777f17fa96fa0f7fd383e742479"
S4HANA22_FOUNDATIONS_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001542872021"   # SAPHOSTAGENT54_54-80004822.SAR        (according to LW docs)
S4HANA22_FOUNDATIONS_KERNEL_SAPHOSTAGENT_MD5="5899a0934bd8d37a887d0d67de6ac0520f907a66ff7c3bc79176fff99171a878"


### SOLMAN 7.2
SOLMAN72_SAPCAR=${SAPCAR}                                                                       
SOLMAN72_SAPCAR_MD5=${SAPCAR_MD5}
SOLMAN72_SWPM=${SWPM_1_0}                                                                                         
SOLMAN72_SWPM_MD5=${SWPM_1_0_MD5} 
SOLMAN72_HANADB=${HANADB_LATEST}                                                                 
SOLMAN72_HANADB_MD5=${HANADB_LATEST_MD5}
SOLMAN72_HANACLIENT=${HANACLIENT_LATEST}
SOLMAN72_HANACLIENT_MD5=${HANACLIENT_LATEST_MD5}
SOLMAN72_EXPORT_PART1="https://softwaredownloads.sap.com/file/0030000000222342021"             # 51054655_1.ZIP                        (according to LW docs)
SOLMAN72_EXPORT_PART1_MD5="66146ff62acb7ef2d99f13eaa4cb71b63e51a0dd35591ac80484ffb890e3e7e4"
SOLMAN72_EXPORT_PART2="https://softwaredownloads.sap.com/file/0030000000222362021"             # 51054655_2.ZIP                        (according to LW docs)
SOLMAN72_EXPORT_PART2_MD5="b5ea2e9024db3bfe50ce422652f04194b7af4f8fdea7f42809f8e44ea546d6ab"
SOLMAN72_EXPORT_PART3="https://softwaredownloads.sap.com/file/0030000000222352021"             # 51054655_3.ZIP                        (according to LW docs)
SOLMAN72_EXPORT_PART3_MD5="178ed3a7bc50c82a9ba2d7dafb183c8f4721f3dcad5a8d89d84f8e409ee1e3db"
SOLMAN72_EXPORT_PART4="https://softwaredownloads.sap.com/file/0030000000221892021"             # 51054655_4.ZIP                        (according to LW docs)
SOLMAN72_EXPORT_PART4_MD5="09bc876af4ddb19736e2ef9c58ec10915b8db1cdcd647f56701b6a0537069b7b"
SOLMAN72_KERNEL_IGSEXE="https://softwaredownloads.sap.com/file/0020000001632902020"            # igsexe_12-80003187.sar                (according to LW docs)
SOLMAN72_KERNEL_IGSEXE_MD5="414ab4e14e3985e03dfbc1fcc8fdfe66b0972cfcbbacf80fc4b46c93f20a557e"
SOLMAN72_KERNEL_IGSHELPER="https://softwaredownloads.sap.com/file/0020000000703122018"         # igshelper_17-10010245.sar             (according to LW docs)
SOLMAN72_KERNEL_IGSHELPER_MD5="bc405afc4f8221aa1a10a8bc448f8afd9e4e00111100c5544097240c57c99732"
SOLMAN72_KERNEL_SAPEXE="https://softwaredownloads.sap.com/file/0020000001523262020"            # SAPEXE_700-80002573.SAR               (according to LW docs)
SOLMAN72_KERNEL_SAPEXE_MD5="0aa8fd962c91674f7cb082d3e1d980207dc853bcce4abcb2da9a33f2b7683fdb"
SOLMAN72_KERNEL_SAPEXEDB="https://softwaredownloads.sap.com/file/0020000001523902020"          # SAPEXEDB_700-80002572.SAR             (according to LW docs)
SOLMAN72_KERNEL_SAPEXEDB_MD5="ebea79b86776d5b14ec03bcd6e473982196d2ceb7c9828e38fa8fa40fa6038e4"
SOLMAN72_KERNEL_SAPHOSTAGENT="https://softwaredownloads.sap.com/file/0020000001725602020"      # SAPHOSTAGENT49_49-20009394.SAR        (according to LW docs)
SOLMAN72_KERNEL_SAPHOSTAGENT_MD5="2e3b9f3572e5e15b72fdb2189ee04cf8efcdfec2fd18f35bd68a5518c9e78b9d"
SOLMAN72_KERNEL_SAPJVM="https://softwaredownloads.sap.com/file/0020000000936762022"            # SAPJVM8_89-80000202.SAR               (according to LW docs)
SOLMAN72_KERNEL_SAPJVM_MD5="3745917ad84817d6a1239feac5a014a0c85c3e576c80e55b590fc13a429433fc"


# --- Housekeeping variables ---

SUCCESSFUL_DOWNLOADS=""
SUCCESSFUL_UPLOADS=""
FAILED_UPLOADS=""
FAILED_DOWNLOADS=""
SKIPPED_FILES=""
MEDIA_PATH="/media/LaunchWizard-"$LW_DEPLOYMENT_NAME"/compressed";

if [[ $FLAG_DOWNLOAD = true ]]
then
cd $home
mkdir -p "mymedia"
MEDIA_PATH="mymedia/LaunchWizard-"$LW_DEPLOYMENT_NAME"/compressed";
fi

echo "SAP_PRODUCT_ID: $SAP_PRODUCT_ID";

# --- Getting files for the chosen SAP product ---

case $SAP_PRODUCT_ID in

  "swpm1")
     PRODUCT_PREFIX="SWPM_1_0"
     EXPORTS=0
  ;;

  "swpm2")
     PRODUCT_PREFIX="SWPM_2_0"
     EXPORTS=0
  ;;

  "hana")
     PRODUCT_PREFIX="HANA_CLIENT"
     EXPORTS=0
  ;;

  "sapNetweaver-750")
     PRODUCT_PREFIX="NW750"
     EXPORTS=1
  ;;

  "sapNetweaverJavaOnly-750")
    PRODUCT_PREFIX="NW750_JAVA"
    EXPORTS=1
  ;;

  "sapNetweaver-752")
     PRODUCT_PREFIX="NW752"
     EXPORTS=2
  ;;

  "sapbw4hana-2.0")
     PRODUCT_PREFIX="BW4HANA20"
     EXPORTS=7
  ;;

  "sapbw4hana-2021")
     PRODUCT_PREFIX="BW4HANA21"
     EXPORTS=8
  ;;

  "saps4hana-1909")
     PRODUCT_PREFIX="S4HANA19"
     EXPORTS=25
  ;;

  "saps4hana-2020")
     PRODUCT_PREFIX="S4HANA20"
     EXPORTS=24
  ;;

  "saps4hana-2021")
     PRODUCT_PREFIX="S4HANA21"
     EXPORTS=28
  ;;

  "saps4hana-2022")
     PRODUCT_PREFIX="S4HANA22"
     EXPORTS=30
  ;;

  "saps4hanafoundations-2021")
     PRODUCT_PREFIX="S4HANA21_FOUNDATIONS"
     EXPORTS=8
  ;;

  "saps4hanafoundations-2022")
     PRODUCT_PREFIX="S4HANA22_FOUNDATIONS"
     EXPORTS=9
  ;;

   "sapsolman-7.2")
     PRODUCT_PREFIX="SOLMAN72"
     EXPORTS=4
  ;;

  *)
     echo -e "${RED}Error:${NO_COLOR} Unknown SAP_PRODUCT_ID, allowed values:"
     echo ""
     echo "-> sapNetweaver-750"
     echo "-> sapNetweaverJavaOnly-750"
     echo "-> sapNetweaver-752"
     echo "-> sapbw4hana-2021"
     echo "-> sapbw4hana-2.0"
     echo "-> saps4hana-1909"
     echo "-> saps4hana-2020"
     echo "-> saps4hana-2021"
     echo "-> saps4hana-2022"
     echo "-> saps4hanafoundations-2021"
     echo "-> saps4hanafoundations-2022"
     echo "-> sapsolman-7.2"
     echo ""
     echo "Exiting!";
     exit 1
  ;;

esac

echo "Prefix: "$PRODUCT_PREFIX;
echo "Media path: " $MEDIA_PATH;

# --- Validate download links for the chosen stack ---

if [[ $FLAG_VALIDATE = true ]]
then
  echo ""
  echo "---------------------------------------------------"
  echo "Validating download links for $SAP_PRODUCT_ID"
  echo "---------------------------------------------------"
  echo ""


  # Technical Foundation
  echo "Technical foundation download links"
  echo ""
  for i in SAPCAR SWPM KERNEL_IGSEXE KERNEL_IGSHELPER KERNEL_SAPEXE KERNEL_SAPEXEDB KERNEL_SAPHOSTAGENT KERNEL_SAPJVM HANACLIENT HANADB 
  do
    ITEM_VARIABLE=`echo "$PRODUCT_PREFIX"_"$i"`;
    SWDC_URL=`echo "${!ITEM_VARIABLE}"`


    # not all stacks necessarily have all the same technical foundation parts (e.g. SAPJVM is only valid for sapsolman-7.2 and sapNetweaverJavaOnly-750)
    if [[ $SWDC_URL != "" ]]
    then
      echo -n "Validating link for "${ITEM_VARIABLE}
      WGET_LAST_HTTP_RC=`wget -q -r -U "SAP Download Manager" --timeout=30 --server-response --spider --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}'`

      if [[ $WGET_LAST_HTTP_RC != "200" ]] 
      then 
        echo -e " ${RED}...failed!${NO_COLOR} (HTTP code: "${WGET_LAST_HTTP_RC}")"
        exit 1
      else
        echo -e " ${GREEN}...success!${NO_COLOR} (HTTP code: "${WGET_LAST_HTTP_RC}")"
      fi
    fi
  done

  # Exports
  echo ""
  echo "SAP Export download links"
  echo ""
  for j in `seq $EXPORTS`
  do
    ITEM_VARIABLE=`echo "$PRODUCT_PREFIX"_EXPORT_PART"$j"`;
    SWDC_URL=`echo "${!ITEM_VARIABLE}"`

    echo -n "Validating link for "${ITEM_VARIABLE}
    WGET_LAST_HTTP_RC=`wget -q -r -U "SAP Download Manager" --server-response --spider --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}'`

    if [[ $WGET_LAST_HTTP_RC != "200" ]] 
    then 
      echo -e " ${RED}...failed!${NO_COLOR} (HTTP code: "${WGET_LAST_HTTP_RC}")"
      exit 1
    else
      echo -e " ${GREEN}...success!${NO_COLOR} (HTTP code: "${WGET_LAST_HTTP_RC}")"
    fi
  done
  
fi



# --- Start downloading the files for the chosen stack ---

if [[ $FLAG_VALIDATE != true ]]
then

echo ""
echo "---------------------------------------------------"
echo "Preparing technical foundation for $SAP_PRODUCT_ID."
echo "---------------------------------------------------"
#echo ""

for i in SAPCAR SWPM KERNEL_IGSEXE KERNEL_IGSHELPER KERNEL_SAPEXE KERNEL_SAPEXEDB KERNEL_SAPHOSTAGENT KERNEL_SAPJVM HANACLIENT HANADB
do
 ITEM_VARIABLE=`echo "$PRODUCT_PREFIX"_"$i"`;
 ITEM_VARIABLE_MD5=`echo "$PRODUCT_PREFIX"_"$i"_MD5`;
 SWDC_URL=`echo "${!ITEM_VARIABLE}"`
 SWDC_MD5=`echo "${!ITEM_VARIABLE_MD5}"`


 if [[ $i == SAPCAR ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/sapcar`;
   ITEM_BUCKET=$SAP_SAPCAR_SOFTWARE_S3_BUCKET;
 elif [[ $i == SWPM ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/swpm`;
   ITEM_BUCKET=$SAP_SWPM_SOFTWARE_S3_BUCKET;
 elif [[ $i == KERNEL* ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/kernel`;
   ITEM_BUCKET=$SAP_KERNEL_SOFTWARE_S3_BUCKET;
 elif [[ $i == HANADB ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/database`;
   ITEM_BUCKET=$SAP_HANADB_SOFTWARE_S3_BUCKET;
 elif [[ $i = HANACLIENT ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/database_client`;
   ITEM_BUCKET=$SAP_HANACLIENT_SOFTWARE_S3_BUCKET;
 else
   ITEM_PATH=`echo "$MEDIA_PATH"/`;
 fi
 

  # not all stacks necessarily have all the same technical foundation parts (e.g. SAPJVM is only valid for sapsolman-7.2 and sapNetweaverJavaOnly-750)
  if [[ $SWDC_URL != "" ]]
  then
    FILENAME=`wget -q -r -U "SAP Download Manager" --timeout=30 --server-response --spider --content-disposition --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep "Content-Disposition:" | tail -1 | awk -F"filename=" '{print $2}' | tr -d \"`
  fi


 if [[ $FILENAME ]]
 then

    # Is the file already present in the respective bucket? 
    S3_HEAD=$(aws s3 ls "$ITEM_BUCKET/$FILENAME" | grep -v "/$" | wc -l | tr -d ' ')
    if [[ S3_HEAD -eq "1" ]]
    then
       echo ""
       echo -e "Already found a file $FILENAME in bucket $ITEM_BUCKET ${YELLOW}... skipping${NO_COLOR}"
       SKIPPED_FILES+=$ITEM_VARIABLE"\n"
       continue;
    fi
 
    WGET_RC=""
    FAILED_CHECKSUM_RETRIES=0
    while [[ FAILED_CHECKSUM_RETRIES -le 1 ]]
    do
        echo ""
        echo -n "Downloading "$FILENAME;
        WGET_RC=`wget -q -P "$ITEM_PATH" -U "SAP Download Manager" --content-disposition --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL`;

        if [[ $WGET_RC -eq 0 ]]
        then
              echo -e " ${GREEN}...done!${NO_COLOR}"

              echo -n "Comparing MD5 checksums"
              md5=($(sha256sum $ITEM_PATH/$FILENAME))
              if [[ "$md5" == "$SWDC_MD5" ]]
              then
                echo -e " ${GREEN}...checksums ok!${NO_COLOR}"
                SUCCESSFUL_DOWNLOADS+=$ITEM_VARIABLE"\n"

                echo -n "Uploading $ITEM_PATH/$FILENAME to $ITEM_BUCKET"
                AWS_S3_RC=`aws s3 cp "$ITEM_PATH/$FILENAME" "$ITEM_BUCKET/$FILENAME" --quiet` 
                if [[ $AWS_S3_RC -eq 0 ]]
                then
                    echo -e " ${GREEN}...done!${NO_COLOR}"
                    SUCCESSFUL_UPLOADS+=$ITEM_VARIABLE"\n"
                else
                    echo ""
                    echo -e "${RED}Error:${NO_COLOR} Could not upload "$FILENAME" to S3, AWS CLI exit code: "$AWS_S3_RC", does the EC2 role have the correct authorizations?"
                    FAILED_UPLOADS+=$ITEM_VARIABLE"\n"
                fi
              
                echo -n "Cleaning up local file $ITEM_PATH/$FILENAME"
                rm -f "$ITEM_PATH/$FILENAME";
                echo -e " ${GREEN}...done!${NO_COLOR}"
                break;
              else
                echo ""
                echo -e "${RED}Error:${NO_COLOR} Checksums do not match! Cleaning up local (likely corrupt) file "$ITEM_PATH/$FILENAME" and trying again."
                rm -f "$ITEM_PATH/$FILENAME";
                FAILED_CHECKSUM_RETRIES+=1
              fi

        else
          echo ""
          echo -e "${RED}Error:${NO_COLOR} Could not download "$ITEM_VARIABLE", wget exit code: "$WGET_RC", is the URL still valid?"
          echo ""
          FAILED_DOWNLOADS+=$ITEM_VARIABLE"\n"
          break;
        fi

    done  # End while-do-done loop

    if [[ FAILED_CHECKSUM_RETRIES -gt 1 ]]
    then
        echo ""
        echo -e "${RED}Error:${NO_COLOR} Could not download "$ITEM_VARIABLE", two failed checksum validations in a row!";
        echo ""
        FAILED_DOWNLOADS+=$ITEM_VARIABLE"\n"
        break;      
    fi

 else
    echo ""
    echo -e "${RED}Error:${NO_COLOR} Could not determine the filename for "$ITEM_VARIABLE" from SAP's servers, wget exit code: "$?", is the URL still valid?"
    FAILED_DOWNLOADS+=$ITEM_VARIABLE"\n"
 fi
 
done # End for-do-done loop


echo ""
echo "-----------------------------------------------------"
echo "Preparing SAP application export for $SAP_PRODUCT_ID"
echo "-----------------------------------------------------"
#echo ""

ITEM_PATH=`echo "$MEDIA_PATH"/exports`;
ITEM_BUCKET=$SAP_EXPORT_SOFTWARE_S3_BUCKET;

for j in `seq $EXPORTS`
do
 ITEM_VARIABLE=`echo "$PRODUCT_PREFIX"_EXPORT_PART"$j"`;
 ITEM_VARIABLE_MD5=`echo "$PRODUCT_PREFIX"_EXPORT_PART"$j"_MD5`;
 SWDC_URL=`echo "${!ITEM_VARIABLE}"`
 SWDC_MD5=`echo "${!ITEM_VARIABLE_MD5}"`


 FILENAME=`wget -q -r -U "SAP Download Manager" --timeout=30 --server-response --spider --content-disposition --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep "Content-Disposition:" | tail -1 | awk -F"filename=" '{print $2}' | tr -d \"`

 if [[ $FILENAME ]]
 then

    # Is the file already present in the respective bucket? 
    S3_HEAD=$(aws s3 ls "$ITEM_BUCKET/$FILENAME" | grep -v "/$" | wc -l | tr -d ' ')
    if [[ S3_HEAD -eq "1" ]]
    then
       echo ""
       echo -e "Already found a file $FILENAME in bucket $ITEM_BUCKET ${YELLOW}... skipping${NO_COLOR}"
       SKIPPED_FILES+=$ITEM_VARIABLE"\n"
       continue;
    fi


    WGET_RC=""
    FAILED_CHECKSUM_RETRIES=0
    while [[ FAILED_CHECKSUM_RETRIES -le 1 ]]
    do
        echo ""
        echo -n "Downloading $SAP_PRODUCT_ID export filename: "$FILENAME;
        WGET_RC=`wget -q -P "$ITEM_PATH" -U "SAP Download Manager" --content-disposition --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL;`

        if [[ $WGET_RC -eq 0 ]]
          then
              echo -e " ${GREEN}...done!${NO_COLOR}"
              
              echo -n "Comparing MD5 checksums"
              md5=($(sha256sum $ITEM_PATH/$FILENAME))
              if [[ "$md5" == "$SWDC_MD5" ]]
              then
                  echo -e " ${GREEN}...checksums ok!${NO_COLOR}"
                  SUCCESSFUL_DOWNLOADS+=$ITEM_VARIABLE"\n"

                  echo -n "Uploading $ITEM_PATH/$FILENAME to $ITEM_BUCKET"
                  AWS_S3_RC=`aws s3 cp "$ITEM_PATH/$FILENAME" "$ITEM_BUCKET/$FILENAME" --quiet`
                  if [[ $AWS_S3_RC -eq 0 ]]
                  then
                      echo -e " ${GREEN}...done!${NO_COLOR}"
                      SUCCESSFUL_UPLOADS+=$ITEM_VARIABLE"\n"
                  else
                      echo ""
                      echo -e "${RED}Error:${NO_COLOR} Could not upload "$FILENAME" to S3, AWS CLI exit code: "$AWS_S3_RC", does the EC2 role have the correct authorizations?"
                      FAILED_UPLOADS+=$ITEM_VARIABLE"\n"
                  fi
                  echo "Cleaning up local file $ITEM_PATH/$FILENAME"
                  rm -f "$ITEM_PATH/$FILENAME";
                  echo -e " ${GREEN}...done!${NO_COLOR}"
                  break;
              else
                  echo ""
                  echo -e "${RED}Error:${NO_COLOR} Checksums do not match! Cleaning up local (likely corrupt) file "$ITEM_PATH/$FILENAME" and trying again."
                  rm -f "$ITEM_PATH/$FILENAME";
                  FAILED_CHECKSUM_RETRIES+=1;
              fi

          else
              echo ""
              echo -e "${RED}Error:${NO_COLOR} Could not download "$ITEM_VARIABLE", wget exit code: "$WGET_RC", is the URL still valid?";
              echo ""
              FAILED_DOWNLOADS+=$ITEM_VARIABLE"\n"
              break;
          fi

    done # End while-do-done loop

    if [[ FAILED_CHECKSUM_RETRIES -gt 1 ]]
    then
        echo ""
        echo -e "${RED}Error:${NO_COLOR} Could not download "$ITEM_VARIABLE", two failed checksum validations in a row!";
        echo ""
        FAILED_DOWNLOADS+=$ITEM_VARIABLE"\n"
        break;      
    fi

 else
    echo ""
    echo -e "${RED}Error:${NO_COLOR} Could not determine the filename for "$ITEM_VARIABLE" from SAP's servers, wget exit code: "$?", is the URL still valid?"
    FAILED_DOWNLOADS+=$ITEM_VARIABLE"\n"
 fi

done # End for-do-done loop




echo ""
echo "-----------------------------------------------------------"
echo "Summary for downloading/uploading files for $SAP_PRODUCT_ID"
echo "-----------------------------------------------------------"
echo ""

SUCCESSFUL_DOWNLOADS_COUNT=`echo -ne $SUCCESSFUL_DOWNLOADS | wc -l`   # echo -ne as last newline is empty due to how the variable is filled
SUCCESSFUL_UPLOADS_COUNT=`echo -ne $SUCCESSFUL_UPLOADS | wc -l`     # echo -ne as last newline is empty due to how the variable is filled
FAILED_DOWNLOADS_COUNT=`echo -ne $FAILED_DOWNLOADS | wc -l`     # echo -ne as last newline is empty due to how the variable is filled
FAILED_UPLOADS_COUNT=`echo -ne $FAILED_UPLOADS | wc -l`     # echo -ne as last newline is empty due to how the variable is filled
SKIPPED_FILES_COUNT=`echo -ne $SKIPPED_FILES | wc -l`     # echo -ne as last newline is empty due to how the variable is filled

if [[ $SKIPPED_FILES_COUNT -gt 0 ]]
then
  echo -e "${YELLOW}$SKIPPED_FILES_COUNT were skipped due to a file with the same name already being present on the respective S3 bucket!${NO_COLOR}"
  echo ""
fi

if [[ $FAILED_DOWNLOADS_COUNT -gt 0 ]]
then
  echo -e "${RED}Error:${NO_COLOR} $FAILED_DOWNLOADS_COUNT file(s) failed to download: "
  echo -e "- "$FAILED_DOWNLOADS
elif [[ $((FAILED_UPLOADS_COUNT+SUCCESSFUL_UPLOADS_COUNT)) -eq 0 ]]
then
  echo -e "${YELLOW}No files were downloaded from the SAP Support Portal!${NO_COLOR}"
  echo ""
else
 echo -e "${GREEN}$SUCCESSFUL_DOWNLOADS_COUNT file(s) were successfully downloaded from the SAP Support Portal!${NO_COLOR}"
fi

if [[ $FAILED_UPLOADS_COUNT -gt 0 ]]
then
  echo -e "${RED}Error:${NO_COLOR} $FAILED_UPLOADS_COUNT files failed to upload: "
  echo -e "- "$FAILED_UPLOADS
elif [[ $((FAILED_UPLOADS_COUNT+SUCCESSFUL_UPLOADS_COUNT)) -eq 0 ]]
then
  echo -e "${YELLOW}No files were uploaded to Amazon S3!${NO_COLOR}"
  echo ""
else
  echo -e "${GREEN}$SUCCESSFUL_UPLOADS_COUNT ouf of $((FAILED_UPLOADS_COUNT+SUCCESSFUL_UPLOADS_COUNT)) files were successfully uploaded to Amazon S3!${NO_COLOR}"
  echo ""
fi

ERRORS=$(($FAILED_DOWNLOADS_COUNT+$FAILED_UPLOADS_COUNT))
if [[ $ERRORS -gt 0 ]]
then
echo -e "${RED}Error:${NO_COLOR} Download incomplete, check the output above!"
exit 1
fi


fi
