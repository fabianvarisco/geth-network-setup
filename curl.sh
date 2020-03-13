#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# https://geth.ethereum.org/docs/rpc/server

# readonly PROVIDER="http://10.30.215.143:8090"
readonly PROVIDER="http://127.0.0.1:8545"

function exe() {
     local DATA_BEGIN='{"jsonrpc":"2.0","method":'
     local DATA_END=',"id":1}'
     local DATA="${DATA_BEGIN}${1}${DATA_END}"

     echo "$1"
     echo ">"

     curl --noproxy "*" -X POST -H "Content-Type: application/json" --data "$DATA" "$PROVIDER" | jq .result

     echo "=================================================="
}

echo "PROVIDER [$PROVIDER]"
echo ""

exe '"eth_accounts","params":[]'

exe '"eth_pendingTransactions","params":[0]'

exe '"eth_getTransactionCount","params":["0xfe3b557e8fb62b89f4916b721be55ceb828dbd73", "pending"]'

exe '"eth_getTransactionCount","params":["0x627306090abaB3A6e1400e9345bC60c78a8BEf57", "pending"]'

exe '"eth_getTransactionByHash","params":["0x9f565e05eac245a9b70cf728f02575c42526246311101dcf35f4df9b3d62628d"]'

exe '"eth_getTransactionReceipt","params":["0x9f565e05eac245a9b70cf728f02575c42526246311101dcf35f4df9b3d62628d"]'

exe '"eth_getBlockByNumber","params":["0x4E63", false]'

exe '"txpool_content","params":[0]'
