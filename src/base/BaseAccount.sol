// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IBaseAccount} from "src/interfaces/account/IBaseAccount.sol";
import {IEntryPoint} from "src/interfaces/entry-point/IEntryPoint.sol";
import {ECDSA} from "src/libraries/ECDSA.sol";
import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {AccessControl} from "./AccessControl.sol";

/// @title BaseAccount
/// @dev Modified from https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BaseAccount.sol

abstract contract BaseAccount is IBaseAccount, AccessControl {
	using ECDSA for bytes32;

	address internal constant ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

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

	modifier onlyEntryPointOrSelf() {
		assembly ("memory-safe") {
			if and(xor(caller(), ENTRYPOINT), xor(caller(), address())) {
				mstore(0x00, shl(0xe0, 0x8e4a23d6)) // Unauthorized(address)
				mstore(0x04, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff))
				revert(0x00, 0x24)
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

	function executeUserOp(PackedUserOperation calldata userOp, bytes32) external payable virtual onlyEntryPoint {
		bytes calldata callData = userOp.callData[4:];

		assembly ("memory-safe") {
			calldatacopy(0x00, callData.offset, callData.length)

			if iszero(delegatecall(gas(), address(), 0x00, callData.length, 0x00, 0x00)) {
				mstore(0x00, 0xacfdb444) // ExecutionFailed()
				revert(0xc1, 0x04)
			}
		}
	}

	function validateUserOp(
		PackedUserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external virtual onlyEntryPoint payPrefund(missingAccountFunds) returns (uint256 validationData) {
		validationData = _validateSignature(userOp, userOpHash);
		_validateNonce(userOp.nonce);
	}

	function _validateSignature(
		PackedUserOperation calldata userOp,
		bytes32 userOpHash
	) internal virtual returns (uint256 validationData) {
		bool success = _isValidSignature(userOpHash.toEthSignedMessageHash(), userOp.signature);

		assembly ("memory-safe") {
			validationData := iszero(success)
		}
	}

	function _validateNonce(uint256 nonce) internal view virtual {}

	function isValidSignature(bytes32 hash, bytes calldata signature) public view virtual returns (bytes4 magicValue) {
		bool success = _isValidSignature(hash, signature);

		assembly ("memory-safe") {
			magicValue := shl(0xe0, or(0x1626ba7e, sub(0x00, iszero(success))))
		}
	}

	function _isValidSignature(bytes32 hash, bytes calldata signature) internal view virtual returns (bool) {
		// the address of recovered signer must be one of the authorized accounts to be valid
		return isAuthorized(hash.recover(signature));
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
}
