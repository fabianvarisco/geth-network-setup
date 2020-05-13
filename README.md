# GNS - geth-network-setup

### run a DEV node

       $ ./setup.sh reset

`reset` is only valid for `dev` environment.

On `reset` `GNS` creates a miner account and saves its address and pkey into `./dev/.miner`.

know others features runnnig:

       $ ./setup.sh

---

### setup.conf

| var                    | environment | desc                                                              |
| :--------------------- | ----------- | :---------------------------------------------------------------- |
| `ENVIRONMENT`          | all         | `dev`, `bfa.testnet` or `bfa.mainnet`                             |
| `DEV_NETWORK_ID`       | `dev`       | value for `genesis.json` `.config.chainId`                        |
| `CONSTANTINOPLE_BLOCK` | `dev`       | value for `genesis.json` `.config.constantinopleBlock`            |
| `ALLOC_MINER`          | `dev`       | `Y`: value for `genesis.json` `.alloc` using `MINER_ADDRESS`      |
| `EXTRADATA_MINER`      | `dev`       | `Y`: value for `genesis.json` `.extraData` using `MINER_ADDRESS`  |

---

## Dependencies

### docker

`GNS` runs geth stable docker contanier.

### gochain/web3 cli tool

https://github.com/gochain/web3

`GNS` uses this cli tool to extract keys from geth keystores.

Quick one line install:

    curl -LSs https://raw.githubusercontent.com/gochain/web3/master/install.sh | sh

Transfer:

    env WEB3_PRIVATE_KEY=<0xKEY> web3 --rpc-url 127.0.0.1:8089 transfer 999 to <0xPUBLIC_ADDRESS>

### Testing Modules JSON-RPC, WS & GRAPHL

Simple curls to validate the services initialized by Geth

#### json-prc

``` sh
curl -s -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"rpc_modules","id":1}'  http://localhost:8545 | jq .
```

more useful queries

``` sh
curl -s -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"txpool_inspect","params":[], "id":1}'  http://localhost:8545  | jq

curl -s -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"eth_pendingTransactions","params":[], "id":1}'  http://localhost:8545

curl -s -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"eth_gasPrice","id":1}'  http://localhost:8545

curl -s -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}'  http://localhost:8545  | jq .result.number | bc -l

curl -v -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"admin_peers","id":1}'  http://localhost:8545  | jq

curl -s -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'  http://localhost:8545 | jq .result

curl -q -X POST -H "Content-type:application/json" --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xBFA3cC51926B9D371C9E7afb6b5a6b22162fD0C0","latest"],"id":1}'  http://localhost:8545  | jq .result
```

#### ws

```sh
npm install -g wscat

wscat -c  http://localhost:8546 -w 1 -x '{"jsonrpc":"2.0","method":"rpc_modules","id":1}'   | jq .
```

#### graphql

```sh
curl -s -X POST -H "Content-Type: application/graphql" -d '{"query":"{block(number:1) {hash}}"}'  http://localhost:8547/graphql | jq
```

or interactive mode with a browser --> http://localhost:8547/
