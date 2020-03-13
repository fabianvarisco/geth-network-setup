#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"

mkdir -p "$CHAIN_DIR"

if [[ ! -f $GENESIS_FILE ]]; then
   echo "ERROR: GENESIS_FILE [$GENESIS_FILE] not found"
   exit 1
fi

cp -f "$GENESIS_FILE" "$CHAIN_DIR/genesis.json"

echo "GENESIS_FILE [$GENESIS_FILE]"
cat "$GENESIS_FILE"

# Todo: --cache 0 # Asi esta en la BFA, entender que implica

docker run -it --rm \
       -v "$CHAIN_DIR:$DOCKER_CHAIN_DIR" \
       "$IMAGE" \
       --cache 0 \
       --datadir "$DOCKER_CHAIN_DIR/$NODE" \
       init "$DOCKER_CHAIN_DIR/genesis.json"
