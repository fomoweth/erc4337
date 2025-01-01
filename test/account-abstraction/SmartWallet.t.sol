// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2 as console} from "forge-std/Test.sol";

import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract SmartWalletTest is SmartWalletTestBase {
	function setUp() public virtual override {
		super.setUp();
	}

	function test_initializationDisableForImplementation() public virtual {
		assertEq(implementation.owner(), address(1));
		assertEq(implementation.nextAccountId(), 1);
		assertEq(implementation.getAccountsLength(), 1);
		checkLastRevisionSlot(address(implementation), MAX_UINT64);

		bytes32 salt = encodeSalt(signer.addr, SALT_KEY);
		bytes memory params = abi.encode(salt, subAccountAddresses);

		expectRevertInvalidInitialization();
		implementation.initialize(params);
	}
}
