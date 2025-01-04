// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IBaseAccount} from "src/interfaces/wallet/IBaseAccount.sol";
import {IEntryPoint} from "src/interfaces/entry-point/IEntryPoint.sol";
import {ECDSA} from "src/libraries/ECDSA.sol";
import {Call} from "src/types/Call.sol";
import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {AccessControl} from "./AccessControl.sol";

/// @title BaseAccount
/// @dev Modified from https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BaseAccount.sol

abstract contract BaseAccount is IBaseAccount, AccessControl {
	using ECDSA for bytes32;

	address internal constant ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

	uint256 internal constant VALIDATION_SUCCESS = 0;
	uint256 internal constant VALIDATION_FAILED = 1;

	modifier onlyEntryPoint() {
		assembly ("memory-safe") {
			if xor(caller(), ENTRYPOINT) {
				mstore(0x00, shl(0xe0, 0x8e4a23d6)) // Unauthorized(address)
				mstore(0x04, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff))
				revert(0x00, 0x24)
			}
		}
		_;
	}

	modifier onlyEntryPointOrOwner() {
		assembly ("memory-safe") {
			// equivalent to if (msg.sender != ENTRYPOINT && !isAuthorized(msg.sender)) revert Unauthorized(msg.sender);
			if xor(caller(), ENTRYPOINT) {
				mstore(0x00, IS_AUTHORIZED_OFFSET)
				mstore(0x20, ACCESS_CONTROL_STORAGE_SLOT)
				mstore(0x20, keccak256(0x00, 0x40))
				mstore(0x00, caller())

				if iszero(sload(keccak256(0x00, 0x40))) {
					mstore(0x00, shl(0xe0, 0x8e4a23d6)) // Unauthorized(address)
					mstore(0x04, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff))
					revert(0x00, 0x24)
				}
			}
		}
		_;
	}

	modifier payPrefund(uint256 missingAccountFunds) {
		_;
		assembly ("memory-safe") {
			if missingAccountFunds {
				pop(call(gas(), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
			}
		}
	}

	function entryPoint() external view virtual returns (IEntryPoint) {
		return IEntryPoint(ENTRYPOINT);
	}

	function executeUserOp(
		PackedUserOperation calldata userOp,
		bytes32 userOpHash
	) external virtual onlyEntryPointOrOwner {
		//
	}

	function validateUserOp(
		PackedUserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external virtual onlyEntryPoint payPrefund(missingAccountFunds) returns (uint256 validationData) {
		validationData = _validateSignature(userOp, userOpHash);
		_validateNonce(userOp.nonce);
	}

	function execute(
		address target,
		uint256 value,
		bytes calldata data
	) external payable virtual onlyEntryPointOrOwner returns (bytes memory result) {
		assembly ("memory-safe") {
			result := mload(0x40)
			calldatacopy(result, data.offset, data.length)

			if iszero(call(gas(), target, value, result, data.length, codesize(), 0x00)) {
				returndatacopy(result, 0x00, returndatasize())
				revert(result, returndatasize())
			}

			mstore(result, returndatasize())
			let offset := add(result, 0x20)
			returndatacopy(offset, 0x00, returndatasize())
			mstore(0x40, add(offset, returndatasize()))
		}
	}

	function executeBatch(
		Call[] calldata calls
	) external payable virtual onlyEntryPointOrOwner returns (bytes[] memory results) {
		assembly ("memory-safe") {
			results := mload(0x40)
			mstore(results, calls.length)

			let r := add(0x20, results)
			let m := add(r, shl(0x05, calls.length))
			calldatacopy(r, calls.offset, shl(0x05, calls.length))

			// prettier-ignore
			for { let end := m } iszero(eq(r, end)) { r := add(r, 0x20) } {
				let e := add(calls.offset, mload(r))
				let o := add(e, calldataload(add(e, 0x40)))
				calldatacopy(m, add(o, 0x20), calldataload(o))

				if iszero(
					call(gas(), calldataload(e), calldataload(add(e, 0x20)), m, calldataload(o), codesize(), 0x00)
				) {
					returndatacopy(m, 0x00, returndatasize())
					revert(m, returndatasize())
				}

				mstore(r, m)
				mstore(m, returndatasize())
				let p := add(m, 0x20)
				returndatacopy(p, 0x00, returndatasize())
				m := add(p, returndatasize())
			}

			mstore(0x40, m)
		}
	}

	function getDeposit() external view virtual returns (uint256 deposit) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x70a0823100000000000000000000000000000000000000000000000000000000) // balanceOf(address)
			mstore(add(ptr, 0x04), and(address(), 0xffffffffffffffffffffffffffffffffffffffff))

			deposit := mul(
				mload(0x00),
				and(gt(returndatasize(), 0x1f), staticcall(gas(), ENTRYPOINT, ptr, 0x24, 0x00, 0x20))
			)
		}
	}

	function addDeposit() external payable virtual {
		assembly ("memory-safe") {
			// send ETH to EntryPoint instead of invoking depositTo(address)
			if iszero(call(gas(), ENTRYPOINT, callvalue(), 0x00, 0x00, 0x00, 0x00)) {
				let ptr := mload(0x40)
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	function withdrawDepositTo(address recipient, uint256 amount) external payable virtual onlyAuthorized {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x205c287800000000000000000000000000000000000000000000000000000000) // withdrawTo(address,uint256)
			mstore(add(ptr, 0x04), and(recipient, 0xffffffffffffffffffffffffffffffffffffffff))
			mstore(add(ptr, 0x24), amount)

			if iszero(call(gas(), ENTRYPOINT, 0x00, ptr, 0x44, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(ptr, 0x00)
			mstore(add(ptr, 0x20), 0x00)
			mstore(add(ptr, 0x40), 0x00)
		}
	}

	function getNonce() external view virtual returns (uint256 nonce) {
		return getNonce(0);
	}

	function getNonce(uint192 key) public view virtual returns (uint256 nonce) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x35567e1a00000000000000000000000000000000000000000000000000000000) // getNonce(address,uint192)
			mstore(add(ptr, 0x04), and(address(), 0xffffffffffffffffffffffffffffffffffffffff))
			mstore(add(ptr, 0x24), and(key, 0xffffffffffffffffffffffffffffffffffffffffffffffff))

			if iszero(staticcall(gas(), ENTRYPOINT, ptr, 0x44, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			nonce := mload(0x00)
		}
	}

	function useNonce(uint192 key) public virtual onlyAuthorized {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x0bd28e3b00000000000000000000000000000000000000000000000000000000) // incrementNonce(uint192)
			mstore(add(ptr, 0x04), and(key, 0xffffffffffffffffffffffffffffffffffffffffffffffff))

			if iszero(call(gas(), ENTRYPOINT, 0x00, ptr, 0x24, 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(mload(0x40), add(ptr, 0x40))
		}
	}

	function _validateSignature(
		PackedUserOperation calldata userOp,
		bytes32 userOpHash
	) internal virtual returns (uint256 validationData) {
		// the address of recovered signer must be one of the authorized accounts to be validated
		if (!isAuthorized(userOpHash.toEthSignedMessageHash().recover(userOp.signature))) {
			return VALIDATION_FAILED;
		}

		return VALIDATION_SUCCESS;
	}

	function _validateNonce(uint256 nonce) internal view virtual {}
}
