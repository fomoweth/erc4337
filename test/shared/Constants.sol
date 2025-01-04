// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";
import {IEntryPoint} from "src/interfaces/entry-point/IEntryPoint.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Constants is CommonBase {
	uint256 internal constant ETHEREUM_CHAIN_ID = 1;

	uint256 internal constant MAX_UINT256 = (1 << 256) - 1;
	uint160 internal constant MAX_UINT160 = (1 << 160) - 1;
	uint64 internal constant MAX_UINT64 = (1 << 64) - 1;

	uint256 internal constant VALIDATION_SUCCESS = 0;
	uint256 internal constant VALIDATION_FAILED = 1;

	uint256 internal constant SALT_KEY = uint256(bytes32("fomoweth"));

	bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

	bytes32 internal constant LAST_REVISION_SLOT = 0x2dcf4d2fa80344eb3d0178ea773deb29f1742cf017431f9ee326c624f742669b;

	bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;
	bytes4 internal constant ERC1271_INVALID = 0xffffffff;

	IEntryPoint internal constant ENTRYPOINT = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

	Currency internal constant WETH = Currency.wrap(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	Currency internal constant STETH = Currency.wrap(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
	Currency internal constant WSTETH = Currency.wrap(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
	Currency internal constant LINK = Currency.wrap(0x514910771AF9Ca656af840dff83E8264EcF986CA);
	Currency internal constant UNI = Currency.wrap(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
	Currency internal constant USDC = Currency.wrap(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}
