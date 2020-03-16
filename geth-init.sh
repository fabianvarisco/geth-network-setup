#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "$0 running ..."

echo "CHAIN_DIR [$CHAIN_DIR]"
readonly REAL_CHAIN_DIR="$(realpath "$CHAIN_DIR")"
echo "REAL_CHAIN_DIR [$REAL_CHAIN_DIR]"
echo "NODE [$NODE]"
readonly REAL_NODE_DIR="$REAL_CHAIN_DIR/$NODE"
echo "REAL_NODE_DIR [$REAL_NODE_DIR]"

echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"
echo "GETH_IMAGE [$GETH_IMAGE]"
echo "NETWORK_ID [$NETWORK_ID]"
echo "MINER_ADDRESS [$MINER_ADDRESS]"

function make_genesis() {
   mkdir -p "$REAL_NODE_DIR"

   local REAL_GENESIS_PATH="$REAL_NODE_DIR/genesis.json"
   echo "REAL_GENESIS_PATH [$REAL_GENESIS_PATH]"

   if [[ -f $REAL_GENESIS_PATH ]]; then
      echo "TODO: WARNING [$REAL_GENESIS_PATH] already exists !!!"
   fi

   if [[ ! -f $GENESIS_TEMPLATE ]]; then
      echo "ERROR: GENESIS_TEMPLATE [$GENESIS_TEMPLATE] not found"
      exit 1
   fi
   echo "GENESIS_TEMPLATE [$GENESIS_TEMPLATE]"

   local gt="$( cat "$GENESIS_TEMPLATE" )"

   echo "Processing json with jq ..."

   gt="$(echo $gt | jq ".config.chainId = $NETWORK_ID")"

   if [[ -v CONSTANTINOPLE_BLOCK && ! -z $CONSTANTINOPLE_BLOCK ]]; then
      echo "> CONSTANTINOPLE_BLOCK [$CONSTANTINOPLE_BLOCK]"
      gt="$(echo $gt | jq ".config.constantinopleBlock = $CONSTANTINOPLE_BLOCK")"
   fi

   if [[ -v ALLOC_MINER ]]; then
      echo "> ALLOC_MINER [$ALLOC_MINER]"
      case "$ALLOC_MINER" in
      Y | y | 1 | YES | yes | OK | ok | Ok )
         local balance="0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
         local alloc="{\"${MINER_ADDRESS:2}\":{\"balance\": \"$balance\"}}"
         gt="$(echo $gt | jq ".alloc += $alloc")"
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
         gt="$(echo $gt | jq ".extraData = $EXTRA_DATA")"
      esac
   fi

   echo "$gt" > "$REAL_GENESIS_PATH"

   jq . "$REAL_GENESIS_PATH"

   unset gt
   unset REAL_GENESIS_PATH
}

function run_init() {
   # Todo: --cache 0 # Asi esta en la BFA, entender que implica
   docker run -it --rm \
      -v "$REAL_CHAIN_DIR:$DOCKER_CHAIN_DIR" \
      "$GETH_IMAGE" \
      --cache 0 \
      --datadir "$DOCKER_CHAIN_DIR/$NODE" \
      init "$DOCKER_CHAIN_DIR/$NODE/genesis.json"
}

make_genesis

run_init
