#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# https://geth.ethereum.org/docs/rpc/server

# readonly PROVIDER="http://10.30.215.143:8090"
readonly PROVIDER="http://127.0.0.1:8545"
echo "PROVIDER [$PROVIDER]"
echo ">"

function exe() {
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

     curl "$verbose" --noproxy "*" -X POST -H "Content-Type: application/json" --data "$DATA" "$PROVIDER" | jq .result

     echo "=================================================="
     unset verbose
     unset DATA
}

exe web3_clientVersion

exe eth_accounts

exe txpool_content

exe eth_pendingTransactions

exe eth_getBalance '["0x815c9A8159B2a99F3E05062377cC41A5dFF86F53", "latest"]'

exe eth_getTransactionCount '["0x815c9A8159B2a99F3E05062377cC41A5dFF86F53", "latest"]'

exe eth_getTransactionCount '["0x815c9A8159B2a99F3E05062377cC41A5dFF86F53", "pending"]'

exe eth_getTransactionByHash '["0x3720fffb2387cbeb67a0b1e13fb95dfd9b0ab8368453fec7165132a30a22c6c0"]'

exe eth_getBlockByNumber '["0x4E63", false]'
