// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISmartWalletFactory} from "src/interfaces/ISmartWalletFactory.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {ERC1967Clone} from "src/libraries/ERC1967Clone.sol";

/// @title SmartWalletFactory
/// @notice Provides functions to deploy and compute the addresses of SmartWallet clones using the deterministic method

contract SmartWalletFactory is ISmartWalletFactory {
	using BytesLib for bytes;
	using ERC1967Clone for address;

	address public immutable implementation;

	constructor(address erc4337) {
		implementation = erc4337;
	}

	function createAccount(bytes calldata params) public payable virtual returns (address instance) {
		bytes32 salt = params.toBytes32(0);

		assembly ("memory-safe") {
			// validate that the given salt from the parameters starts with the caller's address
			if xor(shr(0x60, salt), caller()) {
				mstore(0x00, 0x2f634836) // SaltDoesNotStartWithCaller()
				revert(0x1c, 0x04)
			}
		}

		bool alreadyDeployed;
		(alreadyDeployed, instance) = implementation.createDeterministic(salt);

		assembly ("memory-safe") {
			if iszero(alreadyDeployed) {
				let ptr := mload(0x40)

				mstore(ptr, 0x439fab9100000000000000000000000000000000000000000000000000000000) // initialize(bytes)
				mstore(add(ptr, 0x04), 0x20)
				mstore(add(ptr, 0x24), params.length)
				mstore(add(ptr, 0x44), and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) // replace the salt with the caller's address
				calldatacopy(add(ptr, 0x64), add(params.offset, 0x20), sub(params.length, 0x20)) // copy the rest of params

				if iszero(call(gas(), instance, 0x00, ptr, add(params.length, 0x44), codesize(), 0x00)) {
					returndatacopy(ptr, 0x00, returndatasize())
					revert(ptr, returndatasize())
				}
			}
		}
	}

	function computeAddress(bytes32 salt) public view virtual returns (address) {
		return implementation.predictDeterministicAddress(salt);
	}
}
