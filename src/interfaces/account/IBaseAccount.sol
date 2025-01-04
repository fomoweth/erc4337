// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Call} from "src/types/Call.sol";
import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {IEntryPoint} from "../entry-point/IEntryPoint.sol";
import {IERC4337Account} from "./IERC4337Account.sol";

interface IBaseAccount is IERC4337Account {
	function entryPoint() external view returns (IEntryPoint);

	function getDeposit() external view returns (uint256 deposit);

	function addDeposit() external payable;

	function withdrawDepositTo(address recipient, uint256 amount) external payable;

	function getNonce() external view returns (uint256 nonce);

	function getNonce(uint192 key) external view returns (uint256 nonce);

	function useNonce(uint192 key) external;
}
