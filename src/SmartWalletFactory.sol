// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISmartWalletFactory} from "src/interfaces/ISmartWalletFactory.sol";
import {BytesLib} from "src/libraries/BytesLib.sol";

/// @title SmartWalletFactory
/// @notice Provides functions for deploying and computing address for the SmartWallet

contract SmartWalletFactory is ISmartWalletFactory {
	using BytesLib for bytes;

	address public immutable implementation;

	constructor(address erc4331) {
		implementation = erc4331;
	}

	function createAccount(bytes calldata params) external payable returns (address account) {}

	function computeAddress(bytes32 salt) public view virtual returns (address account) {}

	function initCodeHash() public view virtual returns (bytes32) {}
}
