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
echo "NODE [$NODE]"

readonly REAL_GETH_INSTANCE="$(realpath "$GETH_INSTANCE")"

if [[ ! -d $REAL_GETH_INSTANCE ]]; then
    echo "ERROR: [$REAL_GETH_INSTANCE] does not exist"
    exit 1
fi

readonly KEYSTORE_DIR="$REAL_GETH_INSTANCE/$NODE/keystore"
echo "KEYSTORE_DIR [$KEYSTORE_DIR]"

if [[ ! -v KEYSTORE_PASSWORD || -z $KEYSTORE_PASSWORD ]]; then
    echo "ERROR: KEYSTORE_PASSWORD empty"
    exit 1
fi

# readonly web3=$(command -v web3)
if [[ -z $(command -v web3) ]]; then
   curl -LSs https://raw.githubusercontent.com/gochain/web3/master/install.sh | sh
fi

for file in $KEYSTORE_DIR/*; do
    echo ">"
    if [[ -f $file ]]; then
        echo "keystore: $file"
        output_reading="$(web3 account extract --keyfile "$file" --password "$KEYSTORE_PASSWORD")"
        echo "$output_reading"
        echo ">"

        if [[ $# == 1 && ! -z $1 ]]; then
            output_file="$(realpath "$1")"
            rm -f "$output_file"

            for token in "Private key: " "Public address: "; do
                output_reading_line=$(echo "$output_reading" | grep "$token")
                array=($output_reading_line)

                if [[ $token == Private* ]]; then
                    var="MINER_PKEY"
                else
                    var="MINER_ADDRESS"
                fi
                echo "${var}=${array[2]}" >> "$output_file"
            done
            echo "" >> "$output_file"
            echo "output file [$output_file]"
            cat "$output_file"
            break
        fi
    fi
done

echo_success
