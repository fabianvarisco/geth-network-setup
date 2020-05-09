[[ -n ${DEBUG:-} ]] && set -x
set -Eeuo pipefail

# Initialize
readonly BASE="$(dirname "$0")"

# Import lib.sh
. "$BASE/lib.sh"

[[ -f setup.conf ]] && source setup.conf

readonly WEB3SCRIPT="${1:-web3.admin.nodeInfo}"

# readonly ATTACH="| geth attach ipc:/ipc/geth.ipc"

readonly ATTACH="| geth attach ipc:/root/.ethereum/$NODE/geth.ipc"


readonly CMD="echo '$WEB3SCRIPT'"

echo "$CMD $ATTACH"

dockerdebug exec -t "$NODE" sh -c "$CMD $ATTACH"

# ./geth-attach-exec.sh web3.eth.accounts
# ./geth-attach-exec.sh web3.eth.getBalance\(web3.eth.accounts[0]\)
# ./geth-attach-exec.sh txpool.inspect
# ./geth-attach-exec.sh web3.eth.protocolVersion
# ./geth-attach-exec.sh web3.eth.getBlock\(\"latest\"\)
