// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISmartWallet} from "src/interfaces/ISmartWallet.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {Call} from "src/types/Call.sol";
import {BaseAccount} from "src/base/BaseAccount.sol";
import {EIP712} from "src/base/EIP712.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Receiver} from "src/base/Receiver.sol";
import {UUPSUpgradeable} from "src/base/UUPSUpgradeable.sol";

/// @title SmartWallet
/// @notice Implementation of ERC4337: Account Abstraction

contract SmartWallet is ISmartWallet, BaseAccount, EIP712, Initializable, Receiver, UUPSUpgradeable {
	using BytesLib for bytes;

	constructor() {
		disableInitializer();
		_initializeOwner(address(1));
	}

	function initialize(bytes calldata data) external virtual initializer {
		_initializeOwner(data.toAddress(0));
		_initializeSubAccounts(data.toAddressArray(1));
	}

	function REVISION() public pure virtual override returns (uint256) {
		return 0x01;
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

	function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

	function _domainNameAndVersion() internal pure virtual override returns (string memory, string memory) {
		return ("Fomo WETH Smart Wallet", "1");
	}

	receive() external payable virtual {}

	fallback() external payable virtual receiverFallback {}
}
