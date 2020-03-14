#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# https://geth.ethereum.org/docs/rpc/server

# readonly PROVIDER="http://10.30.215.143:8090"
readonly PROVIDER="http://127.0.0.1:8545"
echo "PROVIDER [$PROVIDER]"
echo ">"

function exe() {

     local method="\"$1"\"
     local params="\"${2:-[]}"\"

     local DATA="{\"jsonrpc\":\"2.0\",\"method\":${method},\"params\":${params},\"id\":1}"

     echo "$1"
     echo 

     curl --silent --noproxy "*" -X POST -H "Content-Type: application/json" --data "$DATA" "$PROVIDER" | jq .result

     echo "=================================================="
}

exe web3_clientVersion

exe eth_accounts

exe txpool_content

exe eth_pendingTransactions

exe eth_pendingTransactions '["pending"]'

exe eth_getTransactionCount '["0xfe3b557e8fb62b89f4916b721be55ceb828dbd73", "pending"]'

exe eth_getTransactionByHash '["0x9f565e05eac245a9b70cf728f02575c42526246311101dcf35f4df9b3d62628d"]'

exe eth_getTransactionReceipt '["0x9f565e05eac245a9b70cf728f02575c42526246311101dcf35f4df9b3d62628d"]'

exe eth_getBlockByNumber '["0x4E63", false]'
