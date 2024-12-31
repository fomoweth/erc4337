// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Math} from "src/libraries/Math.sol";

using PackedUserOperationLibrary for PackedUserOperation global;

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param accountGasLimits      - Packed gas limits for validateUserOp and gas limit passed to the callData method call.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param gasFees               - packed gas fields maxPriorityFeePerGas and maxFeePerGas - Same as EIP-1559 gas parameters.
 * @param paymasterAndData      - If set, this field holds the paymaster address, verification gas limit, postOp gas limit and paymaster-specific extra data
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct PackedUserOperation {
	address sender;
	uint256 nonce;
	bytes initCode;
	bytes callData;
	bytes32 accountGasLimits;
	uint256 preVerificationGas;
	bytes32 gasFees;
	bytes paymasterAndData;
	bytes signature;
}

/// @title PackedUserOperationLibrary
/// @dev Modified from https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/UserOperationLib.sol

library PackedUserOperationLibrary {
	uint256 internal constant ADDR_SIZE = 20;
	uint256 internal constant PAYMASTER_VALIDATION_GAS_OFFSET = 20;
	uint256 internal constant PAYMASTER_POSTOP_GAS_OFFSET = 36;
	uint256 internal constant PAYMASTER_DATA_OFFSET = 52;

	function encode(PackedUserOperation calldata userOp) internal pure returns (bytes memory) {
		return
			abi.encode(
				userOp.parseSender(),
				userOp.nonce,
				calldataKeccak(userOp.initCode),
				calldataKeccak(userOp.callData),
				userOp.accountGasLimits,
				userOp.preVerificationGas,
				userOp.gasFees,
				calldataKeccak(userOp.paymasterAndData)
			);
	}

	function hash(PackedUserOperation calldata userOp) internal pure returns (bytes32) {
		return keccak256(encode(userOp));
	}

	function gasPrice(PackedUserOperation calldata userOp) internal view returns (uint256) {
		unchecked {
			(uint256 maxPriorityFeePerGas, uint256 maxFeePerGas) = unpackUint(userOp.gasFees);
			if (maxFeePerGas == maxPriorityFeePerGas) return maxFeePerGas;

			return Math.min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
		}
	}

	function parseSender(PackedUserOperation calldata userOp) internal pure returns (address sender) {
		assembly ("memory-safe") {
			sender := calldataload(userOp)
		}
	}

	function parseFactory(PackedUserOperation calldata userOp) internal pure returns (address factory) {
		if (userOp.initCode.length >= ADDR_SIZE) factory = address(bytes20(userOp.initCode[:ADDR_SIZE]));
	}

	function parseInitCode(PackedUserOperation calldata userOp) internal pure returns (bytes calldata) {
		return userOp.initCode.length > ADDR_SIZE ? userOp.initCode[ADDR_SIZE:] : emptyCalldata();
	}

	function parseVerificationGasLimit(PackedUserOperation calldata userOp) internal pure returns (uint256) {
		return unpackHigh128(userOp.accountGasLimits);
	}

	function parseCallGasLimit(PackedUserOperation calldata userOp) internal pure returns (uint256) {
		return unpackLow128(userOp.accountGasLimits);
	}

	function parseMaxPriorityFeePerGas(PackedUserOperation calldata userOp) internal pure returns (uint256) {
		return unpackHigh128(userOp.gasFees);
	}

	function parseMaxFeePerGas(PackedUserOperation calldata userOp) internal pure returns (uint256) {
		return unpackLow128(userOp.gasFees);
	}

	function parsePaymasterVerificationGasLimit(PackedUserOperation calldata userOp) internal pure returns (uint256) {
		return uint128(bytes16(userOp.paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET:PAYMASTER_POSTOP_GAS_OFFSET]));
	}

	function parsePostOpGasLimit(PackedUserOperation calldata userOp) internal pure returns (uint256) {
		return uint128(bytes16(userOp.paymasterAndData[PAYMASTER_POSTOP_GAS_OFFSET:PAYMASTER_DATA_OFFSET]));
	}

	function parsePaymaster(PackedUserOperation calldata userOp) internal pure returns (address paymaster) {
		if (userOp.paymasterAndData.length >= PAYMASTER_DATA_OFFSET) {
			paymaster = address(bytes20(userOp.paymasterAndData[:ADDR_SIZE]));
		}
	}

	function parsePaymasterData(PackedUserOperation calldata userOp) internal pure returns (bytes calldata) {
		return
			userOp.paymasterAndData.length >= PAYMASTER_DATA_OFFSET
				? userOp.paymasterAndData[PAYMASTER_DATA_OFFSET:]
				: emptyCalldata();
	}

	function parsePaymasterStaticFields(
		bytes calldata paymasterAndData
	) internal pure returns (address paymaster, uint256 validationGasLimit, uint256 postOpGasLimit) {
		return (
			address(bytes20(paymasterAndData[:PAYMASTER_VALIDATION_GAS_OFFSET])),
			uint128(bytes16(paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET:PAYMASTER_POSTOP_GAS_OFFSET])),
			uint128(bytes16(paymasterAndData[PAYMASTER_POSTOP_GAS_OFFSET:PAYMASTER_DATA_OFFSET]))
		);
	}

	function unpackUint(bytes32 packed) internal pure returns (uint256 high128, uint256 low128) {
		return (uint128(bytes16(packed)), uint128(uint256(packed)));
	}

	function unpackHigh128(bytes32 packed) internal pure returns (uint256) {
		return uint256(packed) >> 128;
	}

	function unpackLow128(bytes32 packed) internal pure returns (uint256) {
		return uint128(uint256(packed));
	}

	function calldataKeccak(bytes calldata data) internal pure returns (bytes32 digest) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			calldatacopy(ptr, data.offset, data.length)
			digest := keccak256(ptr, data.length)
		}
	}

	function emptyCalldata() internal pure returns (bytes calldata data) {
		assembly ("memory-safe") {
			data.offset := 0x00
			data.length := 0x00
		}
	}
}
