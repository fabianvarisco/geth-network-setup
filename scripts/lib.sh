#!/bin/bash

function echo_red()   { echo -e "\033[1;31m$@\033[0m"; }

function echo_green() { echo -e "\033[1;32m$@\033[0m"; }

function echo_blue() { echo -e "\033[1;34m$@\033[0m"; }


function docker() {
   [[ -v DOCKERDEBUG ]] && echo docker "$@"
   command docker "$@"
}

function echo_sep() {
   for i in {1..80}; do echo -n "-"; done
   echo
   if [[ $# -eq 1 ]]; then
      echo $1
   fi
}

function echo_bold_sep() {
   for i in {1..80}; do echo -n "#"; done
   echo
}

function check_param_file() {
[[ -f "$2" ]] || { echo_red "ERROR: p$1: File [$2] not found !!!"; exit 1; }
}

function check_file() {
[[ -f "$1" ]] || { echo_red "ERROR: File [$1] not found !!!"; exit 1; }
}

function check_file_size() {
[[ -f "$1" && -r "$1" && -s $1 ]] || { echo_red "ERROR: File [$1] not readeable or empty !!!"; exit 1; }
}

function check_dir() {
[[ -d "$1" ]] || { echo_red "ERROR: Dir [$1] not found !!!"; exit 1; }
}

function check_var_empty() {
[[ -z $1 ]] || { echo_red "ERROR: var [$1] is empty !!!"; exit 1; }
}

function check_no_empty_dir() {
check_dir "$1"
local FILES=$(ls -A "$1")
[[ "$FILES" ]] || { echo_red "ERROR: Dir [$1] is empty !!!"; exit 1; }
}

function check_exe() {
local command="$(command -v "$1")"
[[ -x $command ]] && { echo "exe checked [$command]"; } || { echo_red "ERROR: Exe ["$1"] not found !!!"; exit 1; }
}

function check_number_of_args() {
if [[ $1 -ne "$2" ]]; then
   echo_red "ERROR: [$1] unexpected number of args - wait [$2]"
   usage
fi
}

function check_env() {
[[ -v "$1" ]] || { echo_red "ERROR: .env [$1] not found !!!"; exit 1; }
}

function backup_dir() {
local SOURCE_DIR="$1"

local TAG_NAME="-" && [[ "$#" -eq 2 ]] && TAG_NAME="-$2-"

if [[ -d "$SOURCE_DIR" ]]; then

    COMMAND="tar"

    for f in $(find "$SOURCE_DIR/" ); do
        if [[ ! -w $f ]]; then
           COMMAND="sudo tar"
           break
        fi
    done

    mkdir -p "${SOURCE_DIR}-backup"

    local FILE=backup-$(basename "$SOURCE_DIR")$TAG_NAME$(date +%Y%m%d%H%M%S).tgz
    $COMMAND --create --gzip --file="${SOURCE_DIR}-backup/$FILE" "$SOURCE_DIR"
fi
}

function warn_backup_rm() {
    DIR=$1
    if [[ -d $DIR ]]; then
       echo "Directory [$DIR] already exists ..."
       echo "if you continue it will be backuped and replaced ..."
       askProceed
       backup_dir "$DIR"
       for f in $(find "$DIR/" ); do
           if [[ ! -w $f ]]; then
              sudo rm -r "$DIR"
              return 0
           fi
       done
       rm -r "$DIR"
    fi
}

function replaceKeys() {
    local FILE="$1"
    shift
    while [[ $# -gt 0 ]]; do
        local NAME="$1"
        sed -i "s/{{$NAME}}/${!NAME}/g" "$FILE"
        shift
    done
}

# Ask user for confirmation to proceed
function askProceed() {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y )
    echo "proceeding ..."
    ;;
  n | N )
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceed
    ;;
  esac
}

function echo_running() {
    readonly THIS=$(basename "$0")
    echo_bold_sep
    echo_blue "[$THIS] running ..."
}

function echo_success() {
    echo_green "[${THIS:-}] ${1:-} exit OK !!!"
    echo_bold_sep
}

function is_x509_crt() {
    [[ -r "$1" ]] && openssl x509 -in "$1" -text &> /dev/null
}

check_x509_crt() {
is_x509_crt "$1" || { echo_red "ERROR: File ["$1"] is not a x509 certificate !!!"; exit 1; }
}

get_CN_from_CSR() {
   get_CN_from_crypto_material req subject "$1"
}

get_CN_from_crypto_material() {
   case $1 in
   x509 | req ) local type=$1 ;;
   * ) echo_red "ERROR: $0 p1 [$1] must be x509 | req"
       exit 1
   esac
   case $2 in
   subject | issuer ) local subject_issuer=$2 ;;
   * ) echo_red "ERROR: $0 p2 [$1] must be subject | issuer"
       exit 1
   esac

   [[ -s $3 ]] || { echo_red "ERROR: File ["$3"] is not a readeable file !!!"; exit 1; }
   local commonName=$(openssl $1 -noout -$2 -nameopt multiline -in "$3" | grep commonName)
   local array=($commonName)
   echo ${array[2]}
}

function make_msp_config_yaml () {
   local CA_CRT_PATH="$1"
   local OUI="$2"
   local OUTPUT_FILENAME="$3"

# NodeOUs.[Admin|Client|Peer|Orderer]OUIdentifier.Certificate:
# Set this to the path of the CA or intermediate CA certificate under which client (peer, admin or orderer) identities should be validated.
# The field is relative to the MSP root folder.
# This field is optional.
# You can leave this field blank and allow the certificate to be validated under any CA defined in the MSP configuration.

# NodeOUs.[Admin|Client|Peer|Orderer]OUIdentifier.OrganizationalUnitIdentifier:
# Is the OU value that the x509 certificate needs to contain to be considered a client (admin, peer, orderer respectively).
# If this field is empty, then the classification is not applied.

cat <<< "# Generado por $THIS
NodeOUs:
  Enable: true
  ClientOUIdentifier:
#    Certificate: $CA_CRT_PATH
     OrganizationalUnitIdentifier: client
  AdminOUIdentifier:
#    Certificate: $CA_CRT_PATH
     OrganizationalUnitIdentifier: admin
  PeerOUIdentifier:
#    Certificate: $CA_CRT_PATH
     OrganizationalUnitIdentifier: peer
  OrdererOUIdentifier:
#    Certificate: $CA_CRT_PATH
     OrganizationalUnitIdentifier: orderer
" > "$OUTPUT_FILENAME"

# Organizational Units:
# In order to configure the list of Organizational Units that valid members of this MSP should include in their X.509 certificate,
# the config.yaml file needs to specify the organizational unit (OU, for short) identifiers.
# The Certificate field refers to the CA or intermediate CA certificate path under which identities,
# having that specific OU, should be validated.
# The path is relative to the MSP root folder and cannot be empty.

if [[ $OUI != "none" ]]; then
cat <<< "
OrganizationalUnitIdentifiers:
  - Certificate: $CA_CRT_PATH
    OrganizationalUnitIdentifier: $OUI
" >> "$OUTPUT_FILENAME"
fi
}

function jq_check_value() {
   echo "Checking json path ..."
   local JSON_FILE="$1"
   local JSON_PATH="$2"
   local WANT="$3"

   local VALUE=$( jq "$JSON_PATH" "$JSON_FILE" )

   echo "WANT [$WANT] VALUE [$VALUE]"

   [[ $WANT == $VALUE ]]
}
