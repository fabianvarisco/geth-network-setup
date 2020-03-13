#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"
echo "NETWORK_ID [$NETWORK_ID]"
echo "IMAGE [$IMAGE]"
echo "NODE [$NODE]"
echo "MINER_ADDRESS [$MINER_ADDRESS]"

readonly KEYSTORE_PASSWORD_FILENAME=keystore-password.txt
rm -f "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
echo "$KEYSTORE_PASSWORD" > "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
cat "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
readonly PASSWORD_OPTION="--password $DOCKER_CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"

# ToDo: --gcmode archive # Asi esta en la BFA, entender lo que implica

docker run -it --rm \
       --name "$NODE" \
       -v "$CHAIN_DIR:$DOCKER_CHAIN_DIR" \
       -p 8545:8545 -p 8546:8546 -p 8547:8547 -p 30303:30303 \
       "$IMAGE" \
       --datadir "$DOCKER_CHAIN_DIR/$NODE" \
       --networkid "$NETWORK_ID" \
       --nodiscover \
       --nousb \
       --mine --miner.threads=1 --etherbase="$MINER_ADDRESS" \
       --unlock "$MINER_ADDRESS" $PASSWORD_OPTION \
       --rpc --rpcapi="txpool,eth,net,web3,clique" --rpcaddr 0.0.0.0 --rpccorsdomain '*' \
       --syncmode full \
       --gcmode archive \
       --verbosity "6" --vmdebug \

#       dumpconfig
#       --allow-insecure-unlock \
