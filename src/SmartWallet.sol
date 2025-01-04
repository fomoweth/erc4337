// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISmartWallet} from "src/interfaces/ISmartWallet.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";
import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
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

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return _domainSeparator();
	}

	function REVISION() public pure virtual override returns (uint256) {
		return 0x01;
	}

	function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

	function _domainNameAndVersion() internal pure virtual override returns (string memory, string memory) {
		return ("Fomo WETH Smart Wallet", "1");
	}

	receive() external payable virtual {}

	fallback() external payable virtual receiverFallback {}
}
