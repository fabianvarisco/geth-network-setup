#!/bin/bash

set -Eeuo pipefail
#set -x

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "$BASE/scripts/lib.sh"

echo_running

function init() {
    if [[ $1 != "$ENVIRONMENT" ]]; then
       echo_red "ERROR: task [init] - arg2 [$1] must be equal to setup.conf ENVIRONMENT [$ENVIRONMENT]"
       exit 1
    fi
    if [[ $2 != "$NODE" ]]; then
       echo_red "ERROR: task [init] - arg3 [$2] must be equal to setup.conf NODE [$NODE]"
       exit 1
    fi

    "$BASE/scripts/geth-init.sh"
}

function run() {
   "$BASE/scripts/geth-run-node.sh"
}

function test() {
   "$BASE/scripts/curl-test.sh"
}

function clean() {
   case "$1" in
   all )      local TARGET="$GETH_INSTANCE" ;;
   geth )     local TARGET="$GETH_INSTANCE/$NODE/geth" ;;
   keystore ) local TARGET="$GETH_INSTANCE/$NODE/keystore" ;;
   * ) echo_red "ERROR: task [clean] - arg2 [$1] unexpected"
       usage
   esac

   warn_backup_rm "$TARGET"

   if [[ $1 != keystore ]]; then
      local cs
            cs="$(docker container ls -aq)"
      [[ ! -z $cs ]] && docker container stop $cs
      docker system prune
   fi
}

function show_config() {
   echo "ENVIRONMENT [$ENVIRONMENT]"
   echo "NODE [$NODE]"

   echo "GETH_VERSION [$GETH_VERSION]"
   echo "GETH_IMAGE [$GETH_IMAGE]"

   echo "GETH_INSTANCE [$GETH_INSTANCE]"
   echo "DOCKER_GETH_INSTANCE [$DOCKER_GETH_INSTANCE]"
}

function account() {
   local  SUBCOMMAND="$1"
   case "$SUBCOMMAND" in
      new | list )
         "$BASE/scripts/geth-account.sh" "$SUBCOMMAND"
         ;;
      extract )
         "$BASE/scripts/web3-account-extract.sh" "${2:-}"
          ;;
      * ) echo_red "ERROR: arg2 [$SUBCOMMAND] must be a new | list | extract";
         usage;
         ;;
   esac
}

function reset() {
  if [[ ${ENVIRONMENT:=none} != dev ]]; then
     echo_red "ERROR: task [reset] with ENVIRONMENT [$ENVIRONMENT] - wait ENVIRONMENT [dev]"
     exit 1
  fi

  clean all

  readonly MINER_CONF="$BASE/dev/.miner"
  rm -f "$MINER_CONF"

  if [[  ${MINER_ADDRESS:-none} == none || ${MINER_PKEY:-none} == none ]]; then
      account new

      account extract "$MINER_CONF"
  else
      echo "MINER_ADDRESS=$MINER_ADDRESS" >> "$MINER_CONF"
      echo "MINER_PKEY=$MINER_PKEY" >> "$MINER_CONF"
      echo "" >> "$MINER_CONF"
  fi

  init dev "$NODE"

  run

  sleep 5 && test
}

function usage() {
   echo "Usage: $0 task [options]"
   echo
   echo "tasks:"
   echo " show_config: show config ..."
   echo " clean <all|keystore|geth>: backup and remove previous instance"
   echo " accounts new: create an account"
   echo " accounts list: list accounts in keystore"
   echo " accounts extract [ouput-file-name]: extract accounts/privatekeys from keystore (using web3 cli tool)"
   echo " init <dev|bfa.testnet|bfa.mainnet> <node1|node2|...>: init node"
   echo " run"
   echo " test"
   echo " reset: clean, init, run (dev only)"
   exit
}

function main() {

   # Check args
   case "$#" in
   1 | 2 | 3 ) ;;
   * ) echo_red "ERROR: $# unexpected number of params"
      usage
   esac

   readonly SETUP_CONF="$BASE/setup.conf" && check_file "$SETUP_CONF" && source "$SETUP_CONF"

   readonly TASK="${1,,}"

   case "$TASK" in
   clean )
      check_number_of_args "$#" 2 && clean "$2"
      ;;
   conf | config | show_config )
      check_number_of_args "$#" 1 && show_config
      ;;
   init )
      check_number_of_args "$#" 3 && init "$2" "$3"
      ;;
   run )
      check_number_of_args "$#" 1 && run
      ;;
   test )
      check_number_of_args "$#" 1 && test
      ;;
   reset )
      check_number_of_args "$#" 1 && reset
      ;;
   account | accounts )
      case "$#" in
      2 | 3 ) account "$2" "${3:-}" ;;
      * ) echo_red "ERROR: task [$TASK] - [$#] unexpected number or args"
          usage
      esac
      ;;
   *) echo_red "ERROR: arg1 [$1] invalid"
      usage
      ;;
   esac
}

main "$@"

echo_success
