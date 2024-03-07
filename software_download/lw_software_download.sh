#!/bin/bash

#Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#DESCRIPTION: Script for automatically downloading SAP installation files
#TYPE: AWS Launch Wizard for SAP - PreConfiguration script
#TARGET: SAP DB
#EXECUTE: Can be executed standalone or via AWS Launch Wizard for SAP
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
   LW_DEPLOYMENT_SCENARIO=${3}
   echo "Validate Download Links: $FLAG_VALIDATE";
elif [[ "$1" = "download" ]]
then
   FLAG_DOWNLOAD=true
   SAP_PRODUCT_ID=${2}
   LW_DEPLOYMENT_NAME=${SAP_PRODUCT_ID}
   echo "LW_DEPLOYMENT_NAME: "$LW_DEPLOYMENT_NAME;
   S3_BUCKET_PREFIX=${3}
   LW_DEPLOYMENT_SCENARIO=${4}
   SAP_SAPCAR_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/SAPCAR"
   SAP_SWPM_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/SWPM"
   SAP_KERNEL_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/KERNEL"
   SAP_EXPORT_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/EXPORT"
   SAP_RDB_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/RDB"
   SAP_RDBCLIENT_SOFTWARE_S3_BUCKET=${S3_BUCKET_PREFIX}"/RDBCLIENT"

   echo "SAP_SAPCAR_SOFTWARE_S3_BUCKET: "$SAP_SAPCAR_SOFTWARE_S3_BUCKET;
   echo "SAP_SWPM_SOFTWARE_S3_BUCKET: "$SAP_SWPM_SOFTWARE_S3_BUCKET;
   echo "SAP_KERNEL_SOFTWARE_S3_BUCKET: "$SAP_KERNEL_SOFTWARE_S3_BUCKET;
   echo "SAP_EXPORT_SOFTWARE_S3_BUCKET: "$SAP_EXPORT_SOFTWARE_S3_BUCKET;
   echo "SAP_RDB_SOFTWARE_S3_BUCKET: "$SAP_RDB_SOFTWARE_S3_BUCKET;
   echo "SAP_RDBCLIENT_SOFTWARE_S3_BUCKET: "$SAP_RDBCLIENT_SOFTWARE_S3_BUCKET;
fi

# --- Retrieving LW CloudFormation stack variables ---

if [[ $FLAG_VALIDATE != true && $FLAG_DOWNLOAD != true ]]
then
source "$DIR/../utils/lw_bootstrap.sh"
fi

echo ""
echo "---------------------------------------------------"
echo "LW Software Download Script"
echo "---------------------------------------------------"
echo ""

# --- Read S-USER ---

echo -n "Retrieving SAP S-User Credentials from AWS Secrets Manager"

SECRETSTRING=$(aws secretsmanager get-secret-value --secret-id sap-s-user --query SecretString --output text)
S_USER=$(echo $SECRETSTRING | grep -o '"username":"[^"]*' | grep -o '[^"]*$')
S_PASS=$(echo $SECRETSTRING | grep -o '"password":"[^"]*' | grep -o '[^"]*$')

if [ -z "$S_USER" ]
then
  echo ""
  echo -e "${RED}Error:${NO_COLOR} Secret sap-s-user or properties username/password not found! Check AWS Secrets Manager!"
  exit 1
fi

echo -e " ${GREEN}...success!${NO_COLOR}"

# --- Validate S-USER ---

echo -n "Validating SAP S-User"
CHECK_URL="https://softwaredownloads.sap.com/file/0020000001450632021" #SAPEXE_50-80005374.SAR from S/4HANA 2021
RETURNCODE=`wget -q -r -U "SAP Download Manager" --max-redirect 1 --timeout=30 --server-response --spider --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $CHECK_URL 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}'`

if [[ $RETURNCODE -ne 200 && $RETURNCODE -ne 302 ]]
then 
  echo ""
  echo -e "${RED}Error:${NO_COLOR} SAP S-User ($S_USER) or password invalid / expired, please verify! (HTTP "${RETURNCODE}")" 
  exit 1
fi

echo -e " ${GREEN}...success!${NO_COLOR}"

echo ""

# --- Read Download Links ---

echo -n "Parsing Download Links"
exec < "$DIR/../software_download/links.csv"
read header
while IFS=";" read -r ID column2 column3 URL column5 DESC MD5 remaining
do
  #echo "$ID"
  #echo "$URL"
  #echo "$MD5"
  #echo ""
  declare ${ID}="$URL"
  declare ${ID}_MD5="$MD5"
  declare ${ID}_DESC="$DESC"
done
echo -e " ${GREEN}...success!${NO_COLOR}"

echo ""

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


if [[ $LW_DEPLOYMENT_SCENARIO = "SapNWOnAseSingle" ]]
then 
  SAP_PRODUCT_ID=$SAP_PRODUCT_ID-ase;
fi

echo "SAP_PRODUCT_ID: $SAP_PRODUCT_ID";

# --- Getting files for the chosen SAP product ---

case $SAP_PRODUCT_ID in

  "swpm1")
     PRODUCT_PREFIX="NW750"
     EXPORTS=0
  ;;

  "swpm2")
     PRODUCT_PREFIX="S4HANA22"
     EXPORTS=0
  ;;

  "sapNetweaver-750")
     PRODUCT_PREFIX="NW750"
     EXPORTS=1
  ;;

  "sapNetweaver-750-ase")
     PRODUCT_PREFIX="NW750_ASE"
     EXPORTS=1
  ;;

  "sapNetweaverJavaOnly-750")
    PRODUCT_PREFIX="NW750_JAVA"
    EXPORTS=1
  ;;

  "sapNetweaverJavaOnly-750-ase")
    PRODUCT_PREFIX="NW750_ASE_JAVA"
    EXPORTS=1
  ;;

  "sapNetweaver-752")
     PRODUCT_PREFIX="NW752"
     EXPORTS=2
  ;;

  "sapNetweaver-752-ase")
     PRODUCT_PREFIX="NW752_ASE"
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

  "saps4hana-2023")
     PRODUCT_PREFIX="S4HANA23"
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

  "saps4hanafoundations-2023")
     PRODUCT_PREFIX="S4HANA23_FOUNDATIONS"
     EXPORTS=9
  ;;

  "sapsolman-7.2")
     PRODUCT_PREFIX="SOLMAN72"
     EXPORTS=4
  ;;

  "sapsolman-7.2-ase")
     PRODUCT_PREFIX="SOLMAN72_ASE"
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
     echo "-> saps4hana-2023"
     echo "-> saps4hanafoundations-2021"
     echo "-> saps4hanafoundations-2022"
     echo "-> saps4hanafoundations-2023"
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
  echo "SAP foundation download links"
  echo ""
  for i in SAPCAR SWPM KERNEL_IGSEXE KERNEL_IGSHELPER KERNEL_SAPEXE KERNEL_SAPEXEDB KERNEL_SAPHOSTAGENT KERNEL_SAPJVM RDBCLIENT RDB 
  do
    ITEM_VARIABLE=`echo "$PRODUCT_PREFIX"_"$i"`;
    SWDC_URL=`echo "${!ITEM_VARIABLE}"`;
    ITEM_DESC_TMP=`echo "$PRODUCT_PREFIX"_"$i"_"DESC"`;
    ITEM_DESC=`echo "${!ITEM_DESC_TMP}"`;

    # not all stacks necessarily have all the same technical foundation parts (e.g. SAPJVM is only valid for sapsolman-7.2 and sapNetweaverJavaOnly-750)
    if [[ $SWDC_URL != "" ]]
    then
      echo -n "Validating link" $SWDC_URL "("$ITEM_DESC") for "${ITEM_VARIABLE}
      WGET_LAST_HTTP_RC=`wget -q -r -U "SAP Download Manager" --max-redirect 1 --timeout=30 --server-response --spider --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}'`

      if [[ $WGET_LAST_HTTP_RC -ne 200 && $WGET_LAST_HTTP_RC -ne 302 ]]
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
    WGET_LAST_HTTP_RC=`wget -q -r -U "SAP Download Manager" --max-redirect 1 --server-response --spider --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep -e "HTTP/*" | tail -1 | awk  '{print $2}'`

    if [[ $WGET_LAST_HTTP_RC -ne 200 && $WGET_LAST_HTTP_RC -ne 302 ]]
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
echo ""

for i in SAPCAR SWPM KERNEL_IGSEXE KERNEL_IGSHELPER KERNEL_SAPEXE KERNEL_SAPEXEDB KERNEL_SAPHOSTAGENT KERNEL_SAPJVM RDBCLIENT RDB
do
 ITEM_VARIABLE=`echo "$PRODUCT_PREFIX"_"$i"`;
 ITEM_VARIABLE_MD5=`echo "$PRODUCT_PREFIX"_"$i"_MD5`;
 SWDC_URL=`echo "${!ITEM_VARIABLE}"`
 SWDC_MD5=`echo "${!ITEM_VARIABLE_MD5}"`
 ITEM_DESC_TMP=`echo "$PRODUCT_PREFIX"_"$i"_"DESC"`;
 ITEM_DESC=`echo "${!ITEM_DESC_TMP}"`;


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
 elif [[ $i == RDB ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/database`;
   ITEM_BUCKET=$SAP_RDB_SOFTWARE_S3_BUCKET;
 elif [[ $i = RDBCLIENT ]]
 then
   ITEM_PATH=`echo "$MEDIA_PATH"/database_client`;
   ITEM_BUCKET=$SAP_RDBCLIENT_SOFTWARE_S3_BUCKET;
 else
   ITEM_PATH=`echo "$MEDIA_PATH"/`;
 fi

 # retrieve filename
 if [[ $SWDC_URL != "" ]]
 then
  echo "" 
  echo -n "Processing "$ITEM_DESC" ("${ITEM_VARIABLE}")"
  echo ""
  FILENAME=`wget -q -r -U "SAP Download Manager" --timeout=30 --server-response --spider --content-disposition --http-user=$S_USER --http-password=$S_PASS --auth-no-challenge $SWDC_URL 2>&1 | grep "Content-Disposition:" | tail -1 | awk -F"filename=" '{print $2}' | tr -d \"`

  # if file does not already exist in S3, download TODO ERROR
  if [[ $FILENAME ]]
  then

    # Is the file already present in the respective bucket? 
    S3_HEAD=$(aws s3 ls "$ITEM_BUCKET/$FILENAME" | grep -v "/$" | wc -l | tr -d ' ')
    if [[ S3_HEAD -eq "1" ]]
    then
       echo -e "Already found a file $FILENAME in bucket $ITEM_BUCKET ${YELLOW}... skipping download${NO_COLOR}"
       SKIPPED_FILES+=$ITEM_VARIABLE"\n"
       continue;
    fi
 
    WGET_RC=""
    FAILED_CHECKSUM_RETRIES=0
    while [[ FAILED_CHECKSUM_RETRIES -le 1 ]]
    do
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

 fi

done # End for-do-done loop


echo ""
echo "-----------------------------------------------------"
echo "Preparing application exports for $SAP_PRODUCT_ID"
echo "-----------------------------------------------------"
echo ""

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
       echo -e "Already found a file $FILENAME in bucket $ITEM_BUCKET ${YELLOW}... skipping download${NO_COLOR}"
       SKIPPED_FILES+=$ITEM_VARIABLE"\n"
       continue;
    fi


    WGET_RC=""
    FAILED_CHECKSUM_RETRIES=0
    while [[ FAILED_CHECKSUM_RETRIES -le 1 ]]
    do
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
  echo -e "${YELLOW}$SKIPPED_FILES_COUNT file(s) were skipped due to a file with the same name already being present in the respective S3 bucket!${NO_COLOR}"
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
  echo -e "${RED}Error:${NO_COLOR} $FAILED_UPLOADS_COUNT file(s) failed to upload: "
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
echo ""
echo "All done!"