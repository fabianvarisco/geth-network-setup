#!/bin/bash

echo "running $0 ..."

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"
echo "NODE [$NODE]"

readonly KEYSTORE_DIR="$CHAIN_DIR/$NODE/keystore"
echo "KEYSTORE_DIR [$KEYSTORE_DIR]"

readonly COMMAND="${1:-list}"

case $COMMAND in
list | new ) ;;
*) echo "ERROR: arg1 [$COMMAND] not found"
   exit 1
   ;;
esac

mkdir -p "$CHAIN_DIR/$NODE"

case "$COMMAND" in
new )
    if [[ ! -v KEYSTORE_PASSWORD || -z $KEYSTORE_PASSWORD ]]; then
        echo "ERROR: env KEYSTORE_PASSWORD empty"
        exit 1
    fi
    readonly KEYSTORE_PASSWORD_FILENAME=keystore-password.txt
    rm -f "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
    echo "$KEYSTORE_PASSWORD" > "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
    cat "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
    readonly PASSWORD_OPTION="--password $DOCKER_CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
    ;;
list )
    if [[ ! -d $KEYSTORE_DIR ]]; then
        echo "ERROR: [$KEYSTORE_DIR] does not exist yet !!!"
        echo "use [./geth-account.sh new] for create one."
        exit 1
    fi
    readonly PASSWORD_OPTION=""
    ;;
* ) echo "ERROR: arg1 [$COMMAND] not found"
    exit 1
    ;;
esac

docker run -it --rm \
       -v "$CHAIN_DIR:$DOCKER_CHAIN_DIR" \
       "$IMAGE" \
       account "$COMMAND" \
       --datadir "$DOCKER_CHAIN_DIR/$NODE" \
       $PASSWORD_OPTION

sudo --preserve-env --set-home -u root chmod +xxx "$CHAIN_DIR/$NODE"
sudo --preserve-env --set-home -u root chmod +xxx "$KEYSTORE_DIR"
sudo --preserve-env --set-home -u root chmod -R +rrr "$KEYSTORE_DIR"

./geth-account-extract.sh
