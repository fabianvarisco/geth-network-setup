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
     local params="\"${2:-[]}"\"

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

exe eth_pendingTransactions '["pending"]'

exe eth_getBalance '["0x198Dc5869055b73037A118ab576884813E1b6e93", "latest"]'

exe eth_getTransactionCount '["0x198Dc5869055b73037A118ab576884813E1b6e93", "pending"]'

exe eth_getTransactionByHash '["0x9f565e05eac245a9b70cf728f02575c42526246311101dcf35f4df9b3d62628d"]'

exe eth_getTransactionReceipt '["0x9f565e05eac245a9b70cf728f02575c42526246311101dcf35f4df9b3d62628d"]'

exe eth_getBlockByNumber '["0x4E63", false]'
