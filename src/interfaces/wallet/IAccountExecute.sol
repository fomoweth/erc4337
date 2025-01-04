// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";

interface IAccountExecute {
	/**
	 * Account may implement this execute method.
	 * passing this methodSig at the beginning of callData will cause the entryPoint to pass the full UserOp (and hash)
	 * to the account.
	 * The account should skip the methodSig, and use the callData (and optionally, other UserOp fields)
	 *
	 * @param userOp              - The operation that was just validated.
	 * @param userOpHash          - Hash of the user's request data.
	 */
	function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external;
}