# Ethereum Docker

Prerequisitos:

1) Docker

2) Intall gochain

       curl -LSs https://raw.githubusercontent.com/gochain/web3/master/install.sh | sh

# Run a dev node

1) create an account

       ./get-account new

1) set account address/key (created on step 1) in .env

       MINNER_ADDRESS=
       MINNER_PKEY=

1) set account address in genesis.json

       "extradata":"...<$MINNER_ADDRESS>..."...
       "alloc":{"<$MINNER_ADDRESS>":{...

1) init node

       ./geth-init.sh

1) run node

       ./geth-run-node.sh

1) test node

       ./curl.sh
