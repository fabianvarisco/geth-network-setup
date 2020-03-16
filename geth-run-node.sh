#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

[[ -f .env ]] && source .env

echo "CHAIN_DIR [$CHAIN_DIR]"
readonly REAL_CHAIN_DIR="$(realpath "$CHAIN_DIR")"
echo "REAL_CHAIN_DIR [$REAL_CHAIN_DIR]"
echo "DOCKER_CHAIN_DIR [$DOCKER_CHAIN_DIR]"
echo "NETWORK_ID [$NETWORK_ID]"
echo "GETH_IMAGE [$GETH_IMAGE]"
echo "NODE [$NODE]"
echo "MINER_ADDRESS [$MINER_ADDRESS]"
echo "GETH_DEBUG [${GETH_DEBUG:=N}]"

readonly KEYSTORE_PASSWORD_FILENAME=keystore-password.txt
rm -f "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
echo "$KEYSTORE_PASSWORD" > "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
cat "$CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"
readonly PASSWORD_OPTION="--password $DOCKER_CHAIN_DIR/$KEYSTORE_PASSWORD_FILENAME"

# ToDo: --gcmode archive # Asi esta en la BFA, entender lo que implica

case "$GETH_IMAGE" in
*v1.8.27 )
    readonly ALLOW_INSECURE_UNLOCK_OPTION="" ;;
* ) readonly ALLOW_INSECURE_UNLOCK_OPTION="--allow-insecure-unlock" ;;
esac

case "$GETH_DEBUG" in
   Y | y | 1 | YES | yes | OK | ok | Ok )
       readonly DEBUG_OPTION="--vmdebug --debug --verbosity 5" ;;
   * ) readonly DEBUG_OPTION="" ;;
esac

docker run -it --rm \
       --name "$NODE" \
       -v "$REAL_CHAIN_DIR:$DOCKER_CHAIN_DIR" \
       -p 8545:8545 -p 8546:8546 -p 8547:8547 -p 30303:30303 \
       "$GETH_IMAGE" \
       --datadir "$DOCKER_CHAIN_DIR/$NODE" \
       --networkid "$NETWORK_ID" \
       --nodiscover \
       --nousb \
       --mine --etherbase="${MINER_ADDRESS:2}" --targetgaslimit 99999999999 \
       --unlock "${MINER_ADDRESS:2}" \
       --rpc --rpcapi="txpool,eth,net,web3,clique" --rpcaddr 0.0.0.0 --rpccorsdomain '*' \
       --syncmode full \
       $DEBUG_OPTION \
       $ALLOW_INSECURE_UNLOCK_OPTION \
       $PASSWORD_OPTION

#       dumpconfig
#       --gcmode archive \
# --miner.threads=1

# Gonzalo:
#
#
# Imagen docker --> "ethereum/client-go:stable"
# Parametros base -->    RPC_ARG=' --networkid 1981 --rpc --rpcaddr=0.0.0.0 --rpcport 8545 --rpcapi=db,eth,net,web3,personal --rpccorsdomain "*"'
# Para Sealer --> ETHERBASE=${ETHERBASE:-"f17f52151EbEF6C7334FAD080c5704D77216b732"}
# ./runnode.sh $NODE_NAME --targetgaslimit 99999999999 --nodiscover --mine --syncmode "full" --etherbase $ETHERBASE -allow-insecure-unlock --unlock "$ETHERBASE" --password /opt/password.$1.txt
