#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

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
   all )      local TARGET="$GETH_INSTANCE/$NODE" ;;
   geth )     local TARGET="$GETH_INSTANCE/$NODE/geth" ;;
   keystore ) local TARGET="$GETH_INSTANCE/$NODE/keystore" ;;
   * ) echo_red "ERROR: task [clean] - arg2 [$1] unexpected"
       usage
   esac

   warn_backup_rm "$TARGET"

   if [[ $1 != keystore ]]; then
      local container
            container="$(docker ps -a --format \{\{.Names\}\} --filter name="$NODE")"
      if [[ ! -z $container ]]; then
         echo "removing container $container ..."
         dockerdebug rm --force "$container"
      fi
   fi
   return 0
}

function show_config() {
   echo "ENVIRONMENT [$ENVIRONMENT]"
   echo "NODE [$NODE]"

   echo "GETH_VERSION [$GETH_VERSION]"
   echo "GETH_IMAGE [$GETH_IMAGE]"

   echo "GETH_INSTANCE [$GETH_INSTANCE]"
   echo "DOCKER_GETH_INSTANCE [$DOCKER_GETH_INSTANCE]"

   echo "GET_DATADIR [$GETH_DATADIR]"
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

  sleep 5

  test

  attach
}

function attach() {
   "$BASE/scripts/geth-attach-exec.sh" "$*"
}

function usage() {
   echo "Usage: $0 task [options]"
   echo
   echo "tasks:"
   echo " show_config: Show config ..."
   echo " clean <all|keystore|geth>: Backup and remove previous instance"
   echo " accounts new: Create an account"
   echo " accounts list: List accounts in keystore"
   echo " accounts extract [ouput-file-name]: Extract accounts/privatekeys from keystore (using web3 cli tool)"
   echo " init <dev|bfa.testnet|bfa.mainnet> <node1|node2|...>: Init node"
   echo " run: Run node"
   echo " test: Test node executing some jsonrpc calls"
   echo " reset: Run clean, init, run (dev only)"
   echo " attach <javascrip>: Ejecute javascript"
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
   attach )
      shift
      attach "$@"
      ;;
   *) echo_red "ERROR: arg1 [$1] invalid"
      usage
      ;;
   esac
}

main "$@"

echo_success
