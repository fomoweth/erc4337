// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IAccessControl {
	function addAccount(address account) external;

	function removeAccountAt(uint256 index) external;

	function getAccountsList() external view returns (address[] memory);

	function getAccountsLength() external view returns (uint256);

	function nextAccountId() external view returns (uint256);

	function getAccountAt(uint256 index) external view returns (address);

	function isAuthorized(address account) external view returns (bool);
}
