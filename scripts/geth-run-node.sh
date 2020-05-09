#!/bin/bash

#!/bin/bash

[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "$BASE/lib.sh"

echo_running

[[ -f setup.conf ]] && source setup.conf

echo "ENVIRONMENT [$ENVIRONMENT]"
echo "NODE [$NODE]"
echo "GETH_INSTANCE [$GETH_INSTANCE]"
readonly REAL_GETH_INSTANCE="$(realpath "$GETH_INSTANCE")"
echo "REAL_GETH_INSTANCE [$REAL_GETH_INSTANCE]"
echo "DOCKER_GETH_INSTANCE [$DOCKER_GETH_INSTANCE]"
echo "DOCKER_GETH_INSTANCE [$DOCKER_DETACHED_MODE]"
echo "GETH_IMAGE [$GETH_IMAGE]"
echo "GETH_DEBUG [${GETH_DEBUG:=N}]"

readonly KEYSTORE_PASSWORD_FILENAME=keystore-password.txt
rm -f "$GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
echo "$KEYSTORE_PASSWORD" > "$GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
cat "$GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"
readonly PASSWORD_OPTION="--password $DOCKER_GETH_INSTANCE/$KEYSTORE_PASSWORD_FILENAME"

case "$GETH_IMAGE" in
*v1.8.27 )
    readonly ALLOW_INSECURE_UNLOCK_OPTION="" ;;
* ) readonly ALLOW_INSECURE_UNLOCK_OPTION="--allow-insecure-unlock" ;;
esac

case "$GETH_DEBUG" in
   Y | y | 1 | YES | yes | OK | ok | Ok )
       readonly DEBUG_OPTIONS="--vmdebug --debug --verbosity 5" ;;
   * ) readonly DEBUG_OPTIONS="" ;;
esac

if [[ $ENVIRONMENT == dev ]]; then

   # miner setting
   if [[ ${MINER_ADDRESS:-none} == none || ${MINER_PKEY:-none} == none ]]; then
      readonly MINER_CONF="$BASE/../dev/.miner"
      [[ -r $MINER_CONF ]] && source "$MINER_CONF"
   fi
   check_env MINER_ADDRESS
   check_env MINER_PKEY
   echo "MINER_ADDRESS [$MINER_ADDRESS]"
   readonly MINER_OPTIONS="--mine --miner.threads=1 --etherbase=${MINER_ADDRESS:2} --unlock ${MINER_ADDRESS:2}"

   readonly NODISCOVER_OPTION="--nodiscover"
   # ToDo: targetgaslimit deprecated => use --miner.gasprice
   readonly TARGETGASLIMIT_OPTION="--targetgaslimit 99999999999"
   readonly NETWORK_ID="$DEV_NETWORK_ID"
else
   readonly MINER_OPTIONS=""
   readonly NODISCOVER_OPTION=""
   readonly TARGETGASLIMIT_OPTION=""
   case "$ENVIRONMENT" in
      bfa.mainnet ) readonly NETWORK_ID="$BFA_MAINNET_NETWORK_ID" ;;
      bfa.testnet ) readonly NETWORK_ID="$BFA_TESTNET_NETWORK_ID" ;;
      * ) echo_red "ERROR: invalid ENVIRONMENT [$ENVIRONMENT]"
         exit 1
   esac
fi
echo "NETWORK_ID [$NETWORK_ID]"

DOCKER_NETWORK_ID=geth_network
if [ -z $(docker network ls --filter name=^${DOCKER_NETWORK_ID}$ --format "{{.Name}}") ]; then
  echo "creating network ${DOCKER_NETWORK_ID}..."
  docker network create $DOCKER_NETWORK_ID
  echo "${DOCKER_NETWORK_ID} created"
fi

# ToDo: --gcmode archive # Asi esta en la BFA, entender lo que implica

DOCKER_CMD="docker run ${DOCKER_DETACHED_MODE:-d} \
       --rm \
       --name "$NODE" \
       --network $DOCKER_NETWORK_ID \
       -v "$REAL_GETH_INSTANCE:$DOCKER_GETH_INSTANCE" \
       -v $HOME/.ethereum:/ipc \
       -p "${RPC_PORT:-8545}":8545 \
       -p "${WS_PORT:-8546}":8546 \
       -p "${GRAPHQL_PORT:-8547}":8547 \
       "$GETH_IMAGE" \
       --networkid "$NETWORK_ID" \
       --datadir "$DOCKER_GETH_INSTANCE/$NODE" \
       --nousb \
       --rpc \
       --graphql \
       --config $DOCKER_GETH_INSTANCE/$NODE/config.toml \
       $TARGETGASLIMIT_OPTION \
       $NODISCOVER_OPTION \
       $MINER_OPTIONS \
       $DEBUG_OPTIONS \
       $ALLOW_INSECURE_UNLOCK_OPTION \
       $PASSWORD_OPTION"

echo "running node..."
echo $DOCKER_CMD | sed 's/\\.*//'
$DOCKER_CMD
docker port "$NODE"
