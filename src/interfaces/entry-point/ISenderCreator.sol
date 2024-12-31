// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ISenderCreator {
	function entryPoint() external view returns (address);

	/**
	 * @dev Creates a new sender contract.
	 * @return sender Address of the newly created sender contract.
	 */
	function createSender(bytes calldata initCode) external returns (address sender);
}
