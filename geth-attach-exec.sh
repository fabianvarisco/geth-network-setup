#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

if [[ -z $1 ]]; then
   readonly WEB3SCRIPT="eth.accounts"
else
   readonly WEB3SCRIPT="$1"
fi

readonly ATTACH="| geth attach ipc:/root/.ethereum/chain1/geth.ipc"

readonly CMD="echo '$WEB3SCRIPT'"

echo "$CMD $ATTACH"

set -x
docker exec -t "$NODE" sh -c "$CMD $ATTACH"

# miner.setEtherbase(accounts[0])
# personal.unlockAccount(eth.accounts[0], "pepe", 5000)
# miner.start(1)
# miner.stop()
