#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Script for automatically downloading and transporting AWS SDK for SAP ABAP files 
#TYPE: AWS Launch Wizard for SAP - PostConfiguration script
#TARGET: PAS
#EXECUTE: Can be executed standalone or via AWS Launch Wizard for SAP
#AUTHOR: meyro@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../utils/colors.sh"

# Check for new awsSdkSapabap releases
ABAPSDK_URL="https://sdk-for-sapabap.aws.amazon.com/awsSdkSapabapV1/release/abapsdk-LATEST.zip"
ABAPSDK_SIG_URL="https://sdk-for-sapabap.aws.amazon.com/awsSdkSapabapV1/release/abapsdk-LATEST.sig"
ABAPSDK_SIGNING_KEY="-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAmS3oN3wKBh4HJOGaOtye
15RR5909nuw0JxOvEDCT7O9wUrXS3mjgEw6b6hvr2dLdoFr+eH4ewT5bVl6U3gDv
051sTdEJJpfLEWJJZZNK3v9fGWKyXgYe+ifmsPmf4lhNd2auzpvIy2UrlSYijCRB
BWZFW+Ux0OkILz+8vCFSXMZ6Z0qtLIlZFbGrn6A5adbwwzfOqkg9BUEZK0wB6TAi
ZTnkMdBZGCBM9K2MRKKMxtrxUn+TFcAYyh5pM9tUAb2q4XE5m7092UnZG7ur/QYl
1FSZwAhQmk8hUPgUaqOOQRC6z3TRzIGKOA/DI0cUPJMzFR4LCxEJkgh4rkRaU9V2
O7DthUpj8b7QcQaiOpnMpBf3zWLgbjNmX0hB0Eprg8/nVRHspf3zuiscJ2lMPkz0
cHOR3lMNsMLzm+d/gVkLt31R/JwAcFCkXTWvR8/VOWNGZZXdVUbefrfI/k7fP60B
bzUrIlN4poq16rc4Tk5Derg+wQ7rOWjXkXop2kiCMjbYo0ol0kS/At64PLjpz8dH
Zg25o79U9EJln+lpqZ297Ks+HoctOv2GPbeeh0s7+N0fRTyOr81EZIURLPKLVQUw
otVRzNDgLOA7eA667NrmegZfHCmqEwK9tXakZUHAcMzRPyhALc/HtmovxdStN9h1
JC4exOGqstAv1fX5QaTbMSECAwEAAQ==
-----END PUBLIC KEY-----"



function download()
{
  MEDIA_PATH=$1
  ABAPSDK_URL=$2
  ABAPSDK_SIG_URL=$3
  ABAPSDK_SIGNING_KEY=$4

  # --- Validate ABAP SDK download link ---

  echo -ne "${YELLOW}Validating link for ABAP SDK:${NO_COLOR} $ABAPSDK_URL"
  WGET_LAST_HTTP_RC=$(wget -q --spider --server-response "$ABAPSDK_URL" 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}')

  if [[ $WGET_LAST_HTTP_RC -ne 200 && $WGET_LAST_HTTP_RC -ne 302 ]]
  then 
    echo -e " ${RED}...failed!${NO_COLOR} (HTTP code: ${WGET_LAST_HTTP_RC})"
    echo "Error: ABAP SDK download link is not valid!"
    exit 1
  else
    echo -e " ${GREEN}...success!${NO_COLOR} (HTTP code: ${WGET_LAST_HTTP_RC})"
  fi
    
  # --- Download & unpack ABAP SDK files---

  echo ""
  echo "---------------------------------------------------------------"
  echo "Downloading, verifying, and copying AWS SDK for SAP ABAP files"
  echo "---------------------------------------------------------------"
  echo ""


  echo -n "Downloading $(basename "$ABAPSDK_URL") to $MEDIA_PATH";
  WGET_LAST_HTTP_RC=$(wget -q --server-response -P "$MEDIA_PATH" "$ABAPSDK_URL" 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}')

  if [[ $WGET_LAST_HTTP_RC -ne 200 && $WGET_LAST_HTTP_RC -ne 302  ]]
  then 
    echo -e " ${RED}...failed!${NO_COLOR} (HTTP code: ${WGET_LAST_HTTP_RC})"
    echo "Error: Failure during download of ABAP SDK files!"
    exit 1
  else
    echo -e " ${GREEN}...success!${NO_COLOR} (HTTP code: ${WGET_LAST_HTTP_RC})"
  fi


  echo -n "Downloading $(basename "$ABAPSDK_SIG_URL") to $MEDIA_PATH";
  WGET_LAST_HTTP_RC=$(wget -q --server-response -P "$MEDIA_PATH" "$ABAPSDK_SIG_URL" 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}')

  if [[ $WGET_LAST_HTTP_RC -ne 200 && $WGET_LAST_HTTP_RC -ne 302  ]]
  then 
    echo -e " ${RED}...failed!${NO_COLOR} (HTTP code: ${WGET_LAST_HTTP_RC})"
    echo "Error: Failure during download of ABAP SDK signature!"
    exit 1
  else
    echo -e " ${GREEN}...success!${NO_COLOR} (HTTP code: ${WGET_LAST_HTTP_RC})"
  fi



  echo ""
  echo -ne "${YELLOW}Validating file integrity of $(basename "$ABAPSDK_URL") ${NO_COLOR}";

  echo "$ABAPSDK_SIGNING_KEY" > "$MEDIA_PATH"/abapsdk-signing-key.pem;



  if ! openssl dgst -sha256 -verify abapsdk-signing-key.pem -keyform PEM -signature abapsdk-LATEST.sig abapsdk-LATEST.zip
  then 
    echo -e " ${RED}...failed!${NO_COLOR}"
    echo "Error: Failure during verification of ABAP SDK signature with signing key!"
    exit 1
  else
    echo -e " ${GREEN}...success!${NO_COLOR}"
  fi

  echo ""
  echo -n "Unzipping contents of $(basename $ABAPSDK_URL) to $MEDIA_PATH";


  if ! unzip -o -q abapsdk-LATEST.zip -d "$MEDIA_PATH"
  then 
    echo -e " ${RED}...failed!${NO_COLOR}"
    exit 1
  else
    echo -e " ${GREEN}...success!${NO_COLOR}"
  fi

  chmod -R 755 "$MEDIA_PATH"

  echo ""
}


# --- OPTIONAL: Generate temporary transport profile (also optional: domain.cfg) ---
function generate_transport_profile() 
{
  MEDIA_PATH=$1
  SAP_SID=$2
  #SAP_CI_HOSTNAME=$3
  #SAP_CI_INSTANCE_NR=$4
  SAP_TRANSPORT_DIRECTORY="/usr/sap/trans"
  SAP_TRANSPORT_PROFILE="TP_DOMAIN_$SAP_SID.PFL"
  SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')
  #SAP_DOMAIN_CFG="DOMAIN.CFG"

  echo -e "${YELLOW}Generating temporary transport profile${NO_COLOR}" "$SAP_TRANSPORT_PROFILE" "${YELLOW}in${NO_COLOR} $SAP_TRANSPORT_DIRECTORY/bin ${YELLOW}with the following contents:${NO_COLOR}";
  echo ""
  # SAP Help Portal - SAP NetWeaver 7.4.15 - Change and Transport System - Transport Profile 
  # https://help.sap.com/docs/SAP_NETWEAVER_740/4a368c163b08418890a406d413933ba7/3dad5b9b4ebc11d182bf0000e829fbfe.html?version=7.4.15&q=software

  sudo -i -u "$SAP_SIDADM" echo "
#TMS:0001:DOMAIN_$SAP_SID\n
#\n
#Created by lw_abapsdk_download_install.sh Post-Script for AWS Launch Wizard for SAP, replace with STMS-generated one at your convenience\n
#\n
#\n
TRANSDIR            = $SAP_TRANSPORT_DIRECTORY\n
#\n
AWS/DUMMY           = 1\n
AWS/NBUFFORM        = 1\n
AWS/TP_VERSION      = 380\n
#\n
$SAP_SID/ABAPNTFMODE     = b\n
$SAP_SID/MT_MODE         = AUTO\n
$SAP_SID/NBUFFORM        = 1\n
$SAP_SID/TP_VERSION      = 380\n
" | sudo -i -u "$SAP_SIDADM" tee "$SAP_TRANSPORT_DIRECTORY/bin/$SAP_TRANSPORT_PROFILE"

  echo -e " ${GREEN}...done!${NO_COLOR}"
  echo ""
  ########
  #echo -n "Generating temporary transport domain " $SAP_DOMAIN_CFG;
  #
  #sudo -i -u $SAP_SIDADM echo "
#Created by lw_abapsdk_download_install.sh Post-Script for AWS Launch Wizard for SAP, replace with STMS-generated one at your convenience\n
#$SAP_CI_HOSTNAME\n
#$SAP_CI_INSTANCE_NR\n
#\n
#DOMAIN_$SAP_SID\n
#Transport domain $SAP_SID\n
#$SAP_SID\n
#System $SAP_SID\n
#$SAP_SID\n
#System $SAP_SID\n
#GROUP_$SAP_SID\n
#Transport group $SAP_SID\n
#" | sudo -i -u "$SAP_SIDADM" tee $SAP_TRANSPORT_DIRECTORY/bin/$SAP_DOMAIN_CFG
  #
  #echo -e " ${GREEN}...done!${NO_COLOR}"
  #########
}


function copy_transport_files()
{
  MEDIA_PATH=$1
  SAP_SID=$2
  SAP_TRANSPORT_DIRECTORY=$3
  SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')

  echo -e "${YELLOW}Copying ABAP SDK Cofiles and Datafiles${NO_COLOR}"
  echo ""
  for i in "$MEDIA_PATH"/transports/*
  do
    PACKAGE_NAME="$(basename $i)"


    echo -n "Copying" $(basename $i/K*.AWS) "($PACKAGE_NAME) to $SAP_TRANSPORT_DIRECTORY/cofiles as $SAP_SIDADM";

    if ! sudo -i -u "$SAP_SIDADM" cp $i/K*.AWS "$SAP_TRANSPORT_DIRECTORY/cofiles/"
    then 
      echo -e " ${RED}...failed!${NO_COLOR}"
      exit 1;
    else
      echo -e " ${GREEN}...success!${NO_COLOR}"
    fi 


    echo -n "Copying" $(basename $i/R*.AWS) "($PACKAGE_NAME) to $SAP_TRANSPORT_DIRECTORY/data as $SAP_SIDADM";

    if ! sudo -i -u "$SAP_SIDADM" cp $i/R*.AWS "$SAP_TRANSPORT_DIRECTORY/data/"
    then 
      echo -e " ${RED}...failed!${NO_COLOR}"
      exit 1;
    else
      echo -e " ${GREEN}...success!${NO_COLOR}"
    fi 

    echo ""

  done

  echo -e " ${GREEN}...all files copied!${NO_COLOR}"
}






function addtobuffer()
{
  MEDIA_PATH=$1
  SAP_SID=$2
  SAP_TRANSPORT_DIRECTORY=$3
  SAP_TRANSPORT_PROFILE=$4
  SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')

  echo ""
  echo "-----------------------------------------------------------"
  echo "Adding AWS SDK for SAP ABAP transports to transport buffer"
  echo "-----------------------------------------------------------"
  echo ""

  for i in "$MEDIA_PATH"/transports/*;
  do 
    PACKAGE_NAME="$(basename $i)"

    echo -e "${YELLOW}Adding" $(basename $i/K*) "($PACKAGE_NAME) to buffer of transport system $SAP_SID${NO_COLOR}";
    
    if ! sudo -i -u "$SAP_SIDADM" tp addtobuffer "AWS$(basename -s .AWS $i/K*)" "$SAP_SID" pf="$SAP_TRANSPORT_DIRECTORY/bin/$SAP_TRANSPORT_PROFILE"
    then 
      echo -e " ${RED}...failed!${NO_COLOR}"
      break
    else
      echo -e " ${GREEN}...success!${NO_COLOR}"
    fi 
  done

# echo -e "${YELLOW}Adding ABAP SDK core transport" $(basename $MEDIA_PATH/transports/core/K*) "($PACKAGE_NAME) to buffer of transport system $SAP_SID${NO_COLOR}";
#
#  if ! sudo -i -u "$SAP_SIDADM" tp addtobuffer "AWS$(basename -s .AWS $MEDIA_PATH/transports/core/K*)" "$SAP_SID" pf="$SAP_TRANSPORT_DIRECTORY/bin/$SAP_TRANSPORT_PROFILE"
#  then 
#    echo -e " ${RED}...failed!${NO_COLOR}"
#  else
#    echo -e " ${GREEN}...success!${NO_COLOR}"
#  fi 
  

  echo ""
}


function importcore()
{
  MEDIA_PATH=$1
  SAP_SID=$2
  SAP_IMPORT_CLIENT=$3
  SAP_TRANSPORT_DIRECTORY=$4
  SAP_TRANSPORT_PROFILE=$5
  SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')
  CORE_TRANSPORT_ID="AWS$(basename -s .AWS $MEDIA_PATH/transports/core/K*)"
  
  # https://help.sap.com/doc/saphelp_nw73ehp1/7.31.19/en-us/3d/ad5b814ebc11d182bf0000e829fbfe/content.htm?no_cache=true
  # tp seems to return 0 even if there were warnings :-(
  echo -e "${YELLOW}Importing AWS SDK for SAP ABAP core transports into $SAP_SID with client $SAP_IMPORT_CLIENT ${NO_COLOR}";
  sudo -i -u "$SAP_SIDADM" tp import "$CORE_TRANSPORT_ID" "$SAP_SID" pf="$SAP_TRANSPORT_DIRECTORY/bin/$SAP_TRANSPORT_PROFILE" client="$SAP_IMPORT_CLIENT" U41
  echo ""
}


function print_usage()
{
  echo ""
	echo "Usage:"
  echo ""
  echo -e "${YELLOW}Postscript mode:${NO_COLOR} $0 lwpostscript { downloadandcopy | addtobuffer | importcore } [ pf=</path/to/custom/transport.pfl> ]"
  echo -e "${YELLOW}Standalone mode:${NO_COLOR} $0 standalone { downloadandcopy | addtobuffer | importcore } sapsid=<###> instancenr=<##> [ client=<###> ] [ pf=/path/to/custom/transport.pfl ]"
  echo ""
  echo -e "${YELLOW}Example: $0 lwpostscript addtobuffer${NO_COLOR}"
  echo "Downloads ABAP SDK files during LW post-script execution and adds the core transport to the SAP system's buffer with a generated transport profile."
  echo ""
  echo -e "${YELLOW}Example: $0 standalone importcore sapsid=S4H instancenr=00 client=100 pf=/usr/sap/trans/bin/TP_DOMAIN_DDD.PFL${NO_COLOR}"
  echo "Downloads ABAP SDK files outside the scope of an LW installation and imports the core transport into a running SAP system, using the provided transport profile and client 100."
  echo ""
  echo -e "${YELLOW}Example: $0 lwpostscript importcore pf=/usr/sap/trans/bin/TP_DOMAIN_AWD.PFL${NO_COLOR}"
  echo "Downloads ABAP SDK files during LW post-script execution and imports the core transport into the SAP system under deployment, using the provided transport profile and client 000 (default)." 
  echo ""
  echo -e "${YELLOW}Example: $0 standalone downloadandcopy${NO_COLOR}"
  echo "Downloads ABAP SDK files outside the scope of an LW installation and copies all co- and data files to /usr/sap/trans"
  echo ""
}









#----------------------------------
# --- PROCESS INPUT PARAMETERS ---
#----------------------------------

RUNMODE=""
OPERATION=""
SAP_SID=""                # provided by bootstrap in lwpostscript mode
SAP_CI_HOSTNAME=""        # provided by bootstrap in lwpostscript mode
SAP_CI_INSTANCE_NR=""     # provided by bootstrap in lwpostscript mode
SAP_IMPORT_CLIENT=""      # defaults to 000 if not provided in standalone mode, hardcoded for lwpostscript
CUSTOM_TRANSPORT_PFL=""   # defaults to /usr/sap/trans/bin/TP_DOMAIN_<SID>.PFL if not provided

# no arguments = fail
if [[ "$#" -eq 0 ]]
then
  print_usage
  exit 1;
fi

# ----- RUNMODE: LW POST-SCRIPT
if [[ "$1" = "lwpostscript" ]]
then
  
  RUNMODE=$1;

  if [[ "$#" -lt 2 || "$#" -gt 3 ]]
  then
     echo "Error: Wrong number of parameters for chosen runmode $1"; 
     print_usage
     exit 1
  fi

  while (("$#"))
  do
    case $2 in
      downloadandcopy) OPERATION="downloadandcopy"; shift;;
      addtobuffer) OPERATION="addtobuffer"; shift;;
      importcore) OPERATION="importcore"; shift;;
      pf=*) CUSTOM_TRANSPORT_PFL="${2#*=}"; shift;;
      *) shift;;
    esac
  done 


  # Populate variables from LW environment
  source "$DIR/../utils/lw_bootstrap.sh"

  SAP_IMPORT_CLIENT="000"
  SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')
  MEDIA_PATH="/media/LaunchWizard-$LW_DEPLOYMENT_NAME/abapsdk"; 
  

  if [[ $SAP_PRODUCT_ID = "sapNetweaverJavaOnly-750" || $SAP_PRODUCT_ID = "sapNetweaverJavaOnly-750-ase" ]]
  then 
    echo -e "${RED}Error:${NO_COLOR} ABAP SDK cannot be installed on Java stacks!"
    exit 1
  fi

# ----- RUNMODE: STANDALONE
elif [[ "$1" = "standalone" ]]
then
  
  RUNMODE=$1;
  
  if [[ "$#" -lt 5 || "$#" -gt 6 ]]
  then
     echo "Error: Wrong number of parameters for chosen runmode $1"; 
     print_usage
     exit 1;
  fi
  
  while (("$#"))
  do
    case $2 in
      downloadandcopy) OPERATION="downloadandcopy"; shift;;
      addtobuffer) OPERATION="addtobuffer"; shift;;
      importcore) OPERATION="importcore"; shift;;
      sapsid=*) SAP_SID="${2#*=}"; shift;;
      instancenr=*) SAP_CI_INSTANCE_NR="${2#*=}"; shift;;
      client=*) SAP_IMPORT_CLIENT="${2#*=}"; shift;;
      pf=*) CUSTOM_TRANSPORT_PFL="${2#*=}"; shift;;
      *) shift;;
    esac
  done


  if [[ $SAP_SID = "" || $SAP_CI_INSTANCE_NR = "" ]]
  then
    echo "Error: Missing mandatory parameter(s) for runmode standalone -> SAP SID and instance number";
    exit 1;
  fi

  SAP_IMPORT_CLIENT="000"
  SAP_SIDADM=$(echo "$SAP_SID"adm | awk '{print tolower($0)}')
  SAP_CI_HOSTNAME=$(hostname)
  MEDIA_PATH="/tmp/mymedia/abapsdk";

  mkdir -p "$MEDIA_PATH";
  echo "Media path: $MEDIA_PATH";
  echo ""

else

  echo "Error: Unsupported runmode $1"; 
  print_usage
  exit 1;
fi




# --- Say hello

echo ""
echo "-------------------------------------------------------"
echo "LW AWS SDK for SAP ABAP Download & Installation Script"
echo "-------------------------------------------------------"
echo "RUNMODE: $RUNMODE"
echo ""

echo "SAP_SID: $SAP_SID";
echo "SAP_CI_INSTANCE_NR: $SAP_CI_INSTANCE_NR";
echo "SAP_CI_HOSTNAME: $SAP_CI_HOSTNAME";
echo "SAP_PRODUCT_ID: $SAP_PRODUCT_ID";


mkdir -p "$MEDIA_PATH";
echo "Media path: $MEDIA_PATH";
echo ""


# do we need to generate a transport profile?
if [[ "$CUSTOM_TRANSPORT_PFL" = "" ]]
then
  generate_transport_profile "$MEDIA_PATH" "$SAP_SID"
  SAP_TRANSPORT_PROFILE="TP_DOMAIN_$SAP_SID.PFL"
  SAP_TRANSPORT_DIRECTORY="/usr/sap/trans"
else
  SAP_TRANSPORT_PROFILE="$(basename $CUSTOM_TRANSPORT_PFL)"
  SAP_TRANSPORT_DIRECTORY="$(cat $CUSTOM_TRANSPORT_PFL 2>&1 | grep "TRANSDIR" | awk '{print $3}')"
fi


if [[ "$OPERATION" = "downloadandcopy" ]]
then
  download "$MEDIA_PATH" "$ABAPSDK_URL" "$ABAPSDK_SIG_URL" "$ABAPSDK_SIGNING_KEY"
  copy_transport_files "$MEDIA_PATH" "$SAP_SID" "$SAP_TRANSPORT_DIRECTORY"
  exit 0
elif [[ "$OPERATION" = "addtobuffer" ]]
then
  download "$MEDIA_PATH" "$ABAPSDK_URL" "$ABAPSDK_SIG_URL" "$ABAPSDK_SIGNING_KEY"
  copy_transport_files "$MEDIA_PATH" "$SAP_SID" "$SAP_TRANSPORT_DIRECTORY"
  addtobuffer "$MEDIA_PATH" "$SAP_SID" "$SAP_TRANSPORT_DIRECTORY" "$SAP_TRANSPORT_PROFILE"
  exit 0
elif [[ "$OPERATION" = "importcore" ]]
then
  download "$MEDIA_PATH" "$ABAPSDK_URL" "$ABAPSDK_SIG_URL" "$ABAPSDK_SIGNING_KEY"å
  copy_transport_files "$MEDIA_PATH" "$SAP_SID" "$SAP_TRANSPORT_DIRECTORY"
  addtobuffer "$MEDIA_PATH" "$SAP_SID" "$SAP_TRANSPORT_DIRECTORY" "$SAP_TRANSPORT_PROFILE"
  importcore "$MEDIA_PATH" "$SAP_SID" "$SAP_IMPORT_CLIENT" "$SAP_TRANSPORT_DIRECTORY" "$SAP_TRANSPORT_PROFILE"
  exit 0
else
  echo "Error: Unsupported operation $OPERATION";
  print_usage
  exit 1
fi