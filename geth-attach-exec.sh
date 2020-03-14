#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

readonly WEB3SCRIPT="${1:-eth.accounts}"

readonly ATTACH="| geth attach ipc:/root/.ethereum/chain1/geth.ipc"

readonly CMD="echo '$WEB3SCRIPT'"

echo "$CMD $ATTACH"

set -x
docker exec -t "$NODE" sh -c "$CMD $ATTACH"

# miner.setEtherbase(accounts[0])
# personal.unlockAccount(eth.accounts[0], "pepe", 5000)
# miner.start(1)
# miner.stop()
