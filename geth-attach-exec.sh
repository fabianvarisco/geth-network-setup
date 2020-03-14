#!/bin/bash

echo "running $0 ..."

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

readonly WEB3SCRIPT="${1:-web3.admin.nodeInfo}"

readonly ATTACH="| geth attach ipc:/root/.ethereum/chain1/geth.ipc"

readonly CMD="echo '$WEB3SCRIPT'"

echo "$CMD $ATTACH"

set -x
docker exec -t "$NODE" sh -c "$CMD $ATTACH"

# ./geth-attach-exec.sh web3.eth.accounts
# ./geth-attach-exec.sh web3.eth.protocolVersion
# ./geth-attach-exec.sh web3.eth.getBlock\(\"latest\"\)
