// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IOwnable2Step {
	function transferOwnership(address account) external;

	function acceptOwnership() external;

	function owner() external view returns (address);

	function pendingOwner() external view returns (address);
}
