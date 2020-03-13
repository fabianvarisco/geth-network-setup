#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
echo "NODE [$NODE]"

readonly GETH_NODE_DIR="$CHAIN_DIR/$NODE/geth"
echo "GETH_NODE_DIR [$GETH_NODE_DIR]"

sudo --preserve-env --set-home -u root rm -rf "$GETH_NODE_DIR"

./geth-init.sh

./geth-run-node.sh
