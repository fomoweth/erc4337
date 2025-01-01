// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2 as console} from "forge-std/Test.sol";

import {SmartWallet} from "src/SmartWallet.sol";

import {BaseTest} from "test/shared/BaseTest.sol";

contract SmartWalletTest is BaseTest {
	SmartWallet internal wallet;

	function setUp() public virtual override {
		super.setUp();

		deployFactory();
	}

	// function test_initializationDisableForImplementation() public virtual {}

	function test_initializeWithoutSubAccounts() public virtual {
		address[] memory accounts = new address[](0);

		expectEmitOwnershipTransferred(address(0), address(this));
		expectEmitAccountAdded(0, address(this));
		expectEmitInitialized(1);

		bytes memory initializer = abi.encode(address(this), accounts);
		implementation.initialize(initializer);

		checkLastRevisionSlot(address(implementation), 1);
		assertEq(implementation.owner(), address(this));
		assertTrue(implementation.isAuthorized(address(this)));
		assertEq(implementation.getAccountAt(0), address(this));
		assertEq(implementation.getAccountsLength(), 1);
		assertEq(implementation.nextAccountId(), 1);

		address[] memory allAccounts = implementation.getAccountsList();
		assertEq(allAccounts.length, 1);
	}

	function test_initializeWithSubAccounts() public virtual {
		address[] memory accounts = new address[](3);
		accounts[0] = makeAddr("Account #0");
		accounts[1] = makeAddr("Account #1");
		accounts[2] = makeAddr("Account #2");

		assertEq(implementation.owner(), address(0));
		assertEq(implementation.nextAccountId(), 0);

		expectEmitOwnershipTransferred(address(0), address(this));
		expectEmitAccountAdded(0, address(this));
		for (uint256 i; i < accounts.length; ++i) expectEmitAccountAdded(i + 1, accounts[i]);
		expectEmitInitialized(1);

		bytes memory initializer = abi.encode(address(this), accounts);
		implementation.initialize(initializer);

		checkLastRevisionSlot(address(implementation), 1);
		assertEq(implementation.owner(), address(this));
		assertTrue(implementation.isAuthorized(address(this)));
		assertEq(implementation.getAccountAt(0), address(this));
		assertEq(implementation.getAccountsLength(), 4);
		assertEq(implementation.nextAccountId(), 4);

		address[] memory allAccounts = implementation.getAccountsList();
		for (uint256 i = 1; i < allAccounts.length; ++i) {
			assertTrue(implementation.isAuthorized(accounts[i - 1]));
			assertEq(accounts[i - 1], allAccounts[i]);
		}
	}

	function test_addAccount() public virtual {
		address[] memory accounts = new address[](3);
		accounts[0] = makeAddr("Account #0");
		accounts[1] = makeAddr("Account #1");
		accounts[2] = makeAddr("Account #2");

		bytes memory initializer = abi.encode(address(this), new address[](0));
		implementation.initialize(initializer);

		vm.prank(accounts[0]);
		expectRevertUnauthorizedOwner();
		implementation.addAccount(accounts[1]);

		expectRevertInvalidAccount();
		implementation.addAccount(address(0));

		expectEmitAccountAdded(1, accounts[0]);
		implementation.addAccount(accounts[0]);
		assertEq(implementation.getAccountsLength(), 2);

		vm.prank(accounts[0]);
		expectRevertUnauthorizedOwner();
		implementation.addAccount(accounts[1]);

		expectEmitAccountAdded(2, accounts[1]);
		implementation.addAccount(accounts[1]);
		assertEq(implementation.getAccountsLength(), 3);

		expectEmitAccountAdded(3, accounts[2]);
		implementation.addAccount(accounts[2]);
		assertEq(implementation.getAccountsLength(), 4);

		expectRevertAuthorizedAlready(accounts[2]);
		implementation.addAccount(accounts[2]);
	}

	function test_removeAccountAt() public virtual {
		address[] memory accounts = new address[](3);
		accounts[0] = makeAddr("Account #0");
		accounts[1] = makeAddr("Account #1");
		accounts[2] = makeAddr("Account #2");

		bytes memory initializer = abi.encode(address(this), accounts);
		implementation.initialize(initializer);

		vm.prank(accounts[1]);
		expectRevertUnauthorizedOwner();
		implementation.removeAccountAt(1);

		expectRevertInvalidAccountId(4);
		implementation.removeAccountAt(4);

		expectEmitAccountRemoved(1, accounts[0]);
		implementation.removeAccountAt(1);
		assertEq(implementation.getAccountsLength(), 3);

		expectEmitAccountRemoved(2, accounts[1]);
		implementation.removeAccountAt(2);
		assertEq(implementation.getAccountsLength(), 2);

		expectEmitAccountRemoved(3, accounts[2]);
		implementation.removeAccountAt(3);
		assertEq(implementation.getAccountsLength(), 1);

		expectRevertInvalidAccountId(3);
		implementation.removeAccountAt(3);
	}
}
