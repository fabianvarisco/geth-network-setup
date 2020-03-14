#!/bin/bash

echo "running $0 ..."

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"

readonly COMMAND="${1:-list}"

case $COMMAND in
list | new ) ;;
*) echo "ERROR: arg1 [$COMMAND] not found"
   exit 1
   ;;
esac

readonly REAL_CHAIN_DIR="$(realpath "$CHAIN_DIR")"

if [[ ! -d $REAL_CHAIN_DIR ]]; then
    echo "ERROR: env CHAIN_DIR"
    exit 1
fi

readonly KEYSTORE_DIR="$REAL_CHAIN_DIR/$NODE/keystore"
echo "KEYSTORE_DIR [$KEYSTORE_DIR]"

# if [[ ! -d $KEYSTORE_DIR ]]; then
#    echo "ERROR: KEYSTORE_DIR [$KEYSTORE_DIR]"
#    exit 1
# fi

if [[ ! -v KEYSTORE_PASSWORD || -z $KEYSTORE_PASSWORD ]]; then
    echo "ERROR: env KEYSTORE_PASSWORD empty"
    exit 1
fi

for file in $KEYSTORE_DIR/*; do
    echo ">"
    if [[ -f $file ]]; then
        echo "Private Key File: $file"
        web3 account extract --keyfile "$file" --password "$KEYSTORE_PASSWORD"
        echo ">"
    fi
done

echo ">"
