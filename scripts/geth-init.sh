#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "$BASE/lib.sh"

echo_running

[[ -f setup.conf ]] && source setup.conf

echo "ENVIRONMENT [$ENVIRONMENT]"
echo "NODE [$NODE]"

echo "GETH_INSTANCE [$GETH_INSTANCE]"
readonly REAL_GETH_INSTANCE="$(realpath "$GETH_INSTANCE")"
echo "REAL_GETH_INSTANCE [$REAL_GETH_INSTANCE]"

readonly REAL_NODE_DIR="$REAL_GETH_INSTANCE/$NODE"
echo "REAL_NODE_DIR [$REAL_NODE_DIR]"

echo "DOCKER_GETH_INSTANCE [$DOCKER_GETH_INSTANCE]"
echo "GETH_IMAGE [$GETH_IMAGE]"

readonly REAL_GENESIS_PATH="$REAL_NODE_DIR/genesis.json"
echo "REAL_GENESIS_PATH [$REAL_GENESIS_PATH]"

function make_dev_genesis() {
   echo "making DEV genesis.json ..."
   readonly GENESIS_TEMPLATE="$BASE/../dev/genesis.json"

   if [[ ! -f $GENESIS_TEMPLATE ]]; then
      echo "ERROR: GENESIS_TEMPLATE [$GENESIS_TEMPLATE] not found"
      exit 1
   fi
   echo "GENESIS_TEMPLATE [$GENESIS_TEMPLATE]"

   if [[ ${MINER_ADDRESS:-none} == none || ${MINER_PKEY:-none} == none ]]; then
      readonly MINER_CONF="$BASE/../dev/.miner"
      [[ -r $MINER_CONF ]] && source "$MINER_CONF"
   fi
   check_env MINER_ADDRESS
   check_env MINER_PKEY
   echo "> MINER_ADDRESS [$MINER_ADDRESS]"

   echo "Processing json with jq ..."

   echo "> DEV_NETWORK_ID [${DEV_NETWORK_ID:=555}]"
   gt="$(jq ".config.chainId = $DEV_NETWORK_ID" "$GENESIS_TEMPLATE")"

   if [[ -v CONSTANTINOPLE_BLOCK && ! -z $CONSTANTINOPLE_BLOCK ]]; then
      echo "> CONSTANTINOPLE_BLOCK [$CONSTANTINOPLE_BLOCK]"
      gt="$(echo "$gt" | jq ".config.constantinopleBlock = $CONSTANTINOPLE_BLOCK")"
   fi

   if [[ -v ALLOC_MINER ]]; then
      echo "> ALLOC_MINER [$ALLOC_MINER]"
      case "$ALLOC_MINER" in
      Y | y | 1 | YES | yes | OK | ok | Ok )
         local balance="0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
         local alloc="{\"${MINER_ADDRESS:2}\":{\"balance\": \"$balance\"}}"
         gt="$(echo "$gt" | jq ".alloc += $alloc")"
         unset balance
         unset alloc
      esac
   fi

   if [[ -v EXTRADATA_MINER ]]; then
      echo "> EXTRADATA_MINER [$EXTRADATA_MINER]"
      case "$EXTRADATA_MINER" in
      Y | y | 1 | YES | yes | OK | ok | Ok )
         local pre="0x0000000000000000000000000000000000000000000000000000000000000000"
         local post="0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
         local EXTRA_DATA="\"${pre}${MINER_ADDRESS:2}${post}\""
         unset pre
         unset post
         gt="$(echo "$gt" | jq ".extraData = $EXTRA_DATA")"
      esac
   fi

   echo "$gt" > "$REAL_GENESIS_PATH"

   jq . "$REAL_GENESIS_PATH"

   unset gt
}

function main() {
   if [[ -d $REAL_NODE_DIR/geth ]]; then
      echo_red "ERROR: [$REAL_NODE_DIR/geth] already exists !!!"
      echo "please, run [\$ setup.sh clean geth] before init."
      exit 1
   fi
   mkdir -p "$REAL_NODE_DIR"

   case "$ENVIRONMENT" in
   dev )
      make_dev_genesis
      readonly CONFIG_TOML="$BASE/../$ENVIRONMENT/config.toml"
      [[ -e $CONFIG_TOML ]] && cp "$CONFIG_TOML" "$REAL_NODE_DIR/"
      readonly NETWORK_ID="$DEV_NETWORK_ID"
      ;;
   bfa.mainnet | bfa.testnet )
      for fn in config.toml genesis.json; do
         f="$BASE/../$ENVIRONMENT/$fn"
         if [[ ! -e $f ]]; then
            echo "ERROR: [$f] not found"
            exit 1
         fi
         cp "$f" "$REAL_NODE_DIR/"
      done
      if [[ $ENVIRONMENT == *mainnet ]]; then
         readonly NETWORK_ID="$BFA_MAINNET_NETWORK_ID"
      else
         readonly NETWORK_ID="$BFA_TESTNET_NETWORK_ID"
      fi
      ;;
   * ) echo_red "ERROR: ENVIRONMENT [$ENVIRONMENT] unkown"
      exit 1
   esac

   echo "NETWORK_ID [$NETWORK_ID]"

   dockerdebug run -it --rm \
      -v "$REAL_GETH_INSTANCE:$DOCKER_GETH_INSTANCE" \
      "$GETH_IMAGE" \
      --cache 0 \
      --datadir "$DOCKER_GETH_INSTANCE/$NODE" \
      init "$DOCKER_GETH_INSTANCE/$NODE/genesis.json"
}

main

echo_success
