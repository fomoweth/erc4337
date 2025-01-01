// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

struct Call {
	address target;
	uint256 value;
	bytes data;
}

interface ISmartWallet {
	function execute(address target, uint256 value, bytes calldata data) external payable returns (bytes memory result);

	function executeBatch(Call[] calldata calls) external payable returns (bytes[] memory results);
}
