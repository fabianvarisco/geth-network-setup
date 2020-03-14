#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"
echo "NETWORK_ID [$NETWORK_ID]"
echo "GETH_IMAGE [$GETH_IMAGE]"

set -x
docker run -it --rm \
       -v "$CHAIN_DIR:$DOCKER_CHAIN_DIR" \
       "$GETH_IMAGE" \
       geth \
       --datadir "$DOCKER_CHAIN_DIR/$NODE" \
       --networkid "$NETWORK_ID" \
       --nodiscover \
       --nousb \
       console

# miner.setEtherbase(accounts[0])
# personal.unlockAccount(eth.accounts[0], "pepe", 5000)
# miner.start(1)
# miner.stop()
