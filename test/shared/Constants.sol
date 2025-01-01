// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";
import {IEntryPoint} from "src/interfaces/entry-point/IEntryPoint.sol";

abstract contract Constants is CommonBase {
	bytes10 internal constant UNLABELED_PREFIX = bytes10("unlabeled:");

	uint256 internal constant ETHEREUM_CHAIN_ID = 1;

	uint256 internal constant BLOCKS_PER_DAY = 7200;
	uint256 internal constant BLOCKS_PER_YEAR = 2628000;
	uint256 internal constant SECONDS_PER_BLOCK = 12;
	uint256 internal constant SECONDS_PER_DAY = 86400;
	uint256 internal constant SECONDS_PER_YEAR = 31536000;

	uint256 internal constant MAX_UINT256 = (1 << 256) - 1;
	uint160 internal constant MAX_UINT160 = (1 << 160) - 1;
	uint128 internal constant MAX_UINT128 = (1 << 128) - 1;
	uint96 internal constant MAX_UINT96 = (1 << 96) - 1;
	uint64 internal constant MAX_UINT64 = (1 << 64) - 1;

	uint256 internal constant VALIDATION_SUCCESS = 0;
	uint256 internal constant VALIDATION_FAILED = 1;

	uint256 internal constant SALT_KEY = uint256(bytes32("fomoweth"));

	bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

	bytes32 internal constant LAST_REVISION_SLOT = 0x2dcf4d2fa80344eb3d0178ea773deb29f1742cf017431f9ee326c624f742669b;

	/// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
	bytes32 internal constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	IEntryPoint internal constant ENTRYPOINT = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);
}
