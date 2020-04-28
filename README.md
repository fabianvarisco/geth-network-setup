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
