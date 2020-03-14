# Ethereum Docker

Prerequisitos:

1) Docker

2) Intall gochain

       curl -LSs https://raw.githubusercontent.com/gochain/web3/master/install.sh | sh

# Run a dev node

1) create an account

       ./get-account new

1) set account address/key (created on step 1) in .env

       MINER_ADDRESS=
       MINER_PKEY=

1) run node

       ./geth-reset-node.sh

1) test node

       ./curl.sh
