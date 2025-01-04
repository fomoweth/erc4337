// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

struct Call {
	address target;
	uint256 value;
	bytes data;
}
