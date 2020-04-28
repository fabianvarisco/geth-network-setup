#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "GETH_INSTANCE [$GETH_INSTANCE]"
echo "DOCKER_GETH_INSTANCE [$DOCKER_GETH_INSTANCE]"
echo "NETWORK_ID [$NETWORK_ID]"
echo "GETH_IMAGE [$GETH_IMAGE]"

set -x
docker run -it --rm \
       -v "$GETH_INSTANCE:$DOCKER_GETH_INSTANCE" \
       "$GETH_IMAGE" \
       geth \
       --datadir "$DOCKER_GETH_INSTANCE/$NODE" \
       --networkid "$NETWORK_ID" \
       --nodiscover \
       --nousb \
       console

# miner.setEtherbase(accounts[0])
# personal.unlockAccount(eth.accounts[0], "pepe", 5000)
# miner.start(1)
# miner.stop()
