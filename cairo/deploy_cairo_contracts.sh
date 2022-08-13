set -e
starknet deploy --network=alpha-goerli --contract ./artifacts/compiled/NFTRentingController.json --no_wallet
