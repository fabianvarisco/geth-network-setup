#!/bin/bash

#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "$BASE/lib.sh"

echo_running

# ACCOUNT=""
# BLOCK="0x4E63"
# TX_HASH="0xc9d52a83a20f6c03a759ee4314f33accd6cbade5449ff7ce4d32994b904a374b"

[[ -f setup.conf ]] && source setup.conf

# https://geth.ethereum.org/docs/rpc/server

if [[ ${GETH_RPC_URL:-none} == none ]]; then
   echo "setting any geth rpc url ..."
   # readonly GETH_RPC_URL="http://10.30.215.143:8090/"
fi
if [[ ${GETH_RPC_URL:-none} == none ]]; then
   echo "ERROR: unsetted GETH_RPC_URL"
   exit 1
fi


echo "ENVIRONMENT [${ENVIRONMENT:-}]"
echo "GETH_RPC_URL [$GETH_RPC_URL]"
echo ">"

function call2() {
     echo "executing method $1 params ${2:-[]} ..."

     local method="\"$1"\"
     local params="${2:-[]}"

     local DATA="{\"jsonrpc\":\"2.0\",\"method\":${method},\"params\":${params},\"id\":1}"

     unset method
     unset params

     if [[ -n ${DEBUG:-} ]]; then
          local verbose="-v"
     else
          local verbose="--silent"
     fi

     echo

     curl "$verbose" --noproxy "*" -H "Content-Type: application/json" --data "$DATA" "$GETH_RPC_URL" | jq .result

     echo "=================================================="
     unset verbose
     unset DATA
}

function call() {
     local FUNCTION="$1"
     if [ $# == 1 ]; then
          call2 "$FUNCTION"
          return 0
     fi
     shift
     local ARGS='[]'
     for ARG in "$@"
     do
        ARG=$(jq -c <<<$ARG . 2>/dev/null || echo $ARG)
        ARGS=$(jq <<<"$ARGS" -c '.+=[$a]' --arg a "$ARG")
     done
     call2 "$FUNCTION" "$ARGS"
}

function set_account() {
     [[ -v ACCOUNT && ! -z $ACCOUNT ]] && return 0

     [[ ${ENVIRONMENT:-none} != dev ]] && return 0

     ACCOUNT="${MINER_ADDRESS:=""}"
     [[ ! -z $ACCOUNT ]] && return 0

     readonly MINER_CONF="$BASE/../dev/.miner"
     if [[ -r $MINER_CONF ]]; then
          source "$MINER_CONF"
          ACCOUNT=${MINER_ADDRESS:-""}
     fi
}

set_account

call web3_clientVersion

call net_peerCount

call eth_syncing

call eth_accounts

call txpool_content

call eth_pendingTransactions

[[ ! -z $ACCOUNT ]] && call eth_getBalance "$ACCOUNT" "latest"

[[ ! -z $ACCOUNT ]] && call eth_getTransactionCount "$ACCOUNT" "latest"

[[ ! -z $ACCOUNT ]] && call eth_getTransactionCount "$ACCOUNT" "pending"

[[ ! -z ${TX_HASH:-} ]] && call eth_getTransactionByHash "$TX_HASH"

[[ ! -z ${BLOCK:-} ]] && call eth_getBlockByNumber "$BLOCK"

true
