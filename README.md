# Smart Wallet

Implementation of contracts for [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) account abstraction.

## Contract Overview

## Usage

Create `.env` file with the following content:

```text
# using Alchemy

ALCHEMY_API_KEY=YOUR_ALCHEMY_API_KEY
RPC_ETHEREUM="https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}"

# using Infura

INFURA_API_KEY=YOUR_INFURA_API_KEY
RPC_ETHEREUM="https://mainnet.infura.io/v3/${INFURA_API_KEY}"

# etherscan

ETHERSCAN_API_KEY_ETHEREUM=YOUR_ETHERSCAN_API_KEY
ETHERSCAN_URL_ETHEREUM="https://api.etherscan.io/api"
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
