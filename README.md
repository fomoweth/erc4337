# Smart Wallet

Implementation of [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337): Account Abstraction.

## Contract Overview

[SmartWalletFactory](https://github.com/fomoweth/erc4337/blob/main/src/SmartWalletFactory.sol) is a factory contract that enables users to deploy SmartWallet contracts in a permissionless manner. During deployment, the contract can be initialized with a specified list of sub-accounts, if provided; otherwise, it defaults to initializing with the deployer's (owner's) address alone.

[SmartWallet](https://github.com/fomoweth/erc4337/blob/main/src/SmartWallet.sol) is the implementation of ERC-4337: Account Abstraction, designed to provide enhanced functionality for user-controlled smart contract wallets. It enables features such as meta-transactions, batched operations, and customizable access control, allowing users to interact with blockchain applications without relying on externally owned accounts (EOAs).

## Additional Context

The first index of the accounts list in the `AccessControl` contract is reserved for the owner of the `SmartWallet` contract. This address cannot be removed independently and will automatically update to the new owner's address when ownership is transferred. Authorized accounts (sub-accounts) are permitted to interact with the `SmartWallet`, including signing transactions, similar to the owner. However, certain actions are restricted exclusively to the owner:

1. **Proxy Upgrades**: Only the owner can initiate and execute proxy upgrades.
2. **Sub-Account Management**: Adding or removing sub-accounts is limited to the owner.
3. **Ownership Transfer**: Ownership can only be transferred to an authorized sub-account and must be performed by the owner.

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
