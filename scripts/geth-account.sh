#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "$BASE/lib.sh"

echo_running

[[ -f setup.conf ]] && source setup.conf

echo "GETH_INSTANCE [$GETH_INSTANCE]"
echo "DOCKER_GETH_INSTANCE [$DOCKER_GETH_INSTANCE]"

readonly REAL_GETH_INSTANCE="$(realpath "$GETH_INSTANCE")"

readonly KEYSTORE_DIR="$REAL_GETH_INSTANCE/$NODE/keystore"
echo "KEYSTORE_DIR [$KEYSTORE_DIR]"

readonly COMMAND="${1:-list}"

case $COMMAND in
list | new ) ;;
*) echo "ERROR: arg1 [$COMMAND] unexpected"
   exit 1
esac

echo "GETH_IMAGE [$GETH_IMAGE]"
echo "NODE [$NODE]"

case "$COMMAND" in
new )
    if [[ ! -v KEYSTORE_PASSWORD || -z $KEYSTORE_PASSWORD ]]; then
        echo "ERROR: env KEYSTORE_PASSWORD empty"
        exit 1
    fi
    readonly KEYSTORE_PASSWORD_FILENAME=keystore-password.txt
    rm -f "$REAL_GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
    echo "$KEYSTORE_PASSWORD" > "$REAL_GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
    cat "$REAL_GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
    readonly PASSWORD_OPTION="--password $DOCKER_GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
    ;;
list )
    if [[ ! -d $KEYSTORE_DIR ]]; then
        echo "ERROR: [$KEYSTORE_DIR] does not exist yet !!!"
        echo "use [setup.sh accounts new] for create one."
        exit 1
    fi
    readonly PASSWORD_OPTION=""
    ;;
* ) echo "ERROR: arg1 [$COMMAND] not found"
    exit 1
    ;;
esac

docker run -it --rm \
       -v "$REAL_GETH_INSTANCE:$DOCKER_GETH_INSTANCE" \
       "$GETH_IMAGE" \
       account "$COMMAND" \
       --datadir "$DOCKER_GETH_INSTANCE/$NODE" \
       $PASSWORD_OPTION

if [[ $COMMAND == new ]]; then
   echo "setting read permisions ..."
   sudo --preserve-env --set-home -u root chmod +xxx "$REAL_GETH_INSTANCE/$NODE"
   sudo --preserve-env --set-home -u root chmod +xxx "$KEYSTORE_DIR"
   sudo --preserve-env --set-home -u root chmod -R +rrr "$KEYSTORE_DIR"
fi

echo_success
