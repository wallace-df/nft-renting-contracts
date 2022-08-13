set -e
mkdir -p artifacts/compiled
mkdir -p artifacts/abis
cd contracts

starknet-compile NFTRentingController.cairo \
    --output ../artifacts/compiled/NFTRentingController.json \
    --abi ../artifacts/abis/NFTRentingController.json

echo "Done!"