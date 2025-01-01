// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ISmartWalletFactory {
	function createAccount(bytes calldata params) external payable returns (address);

	function computeAddress(bytes32 salt) external view returns (address);

	function implementation() external view returns (address);
}
