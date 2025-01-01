// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract AccessControlTest is SmartWalletTestBase {
	address internal account;

	function test_addAccount_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorizedOwner();
		wallet.addAccount(makeAddr("NewSubAccount"));
	}

	function test_addAccount_revertsWithInvalidAccount() public virtual impersonate(signer.addr) {
		expectRevertInvalidAccount();
		wallet.addAccount(account);

		account = subAccounts[0].addr;
		expectRevertAuthorizedAlready(account);
		wallet.addAccount(account);
	}

	function test_addAccount() public virtual impersonate(signer.addr) {
		for (uint256 i; i < numSubAccounts; ++i) {
			wallet.addAccount((account = makeAddr(string.concat("NewSubAccount", vm.toString(i)))));
			assertEq(wallet.getAccountAt(numSubAccounts + i + 1), account);
			assertTrue(wallet.isAuthorized(account));
		}

		assertEq(wallet.getAccountsLength(), numSubAccounts * 2 + 1);
	}

	function test_removeAccountAt_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorizedOwner();
		wallet.removeAccountAt(1);
	}

	function test_removeAccountAt_revertsWithInvalidAccountId() public virtual impersonate(signer.addr) {
		uint256 accountId;
		expectRevertInvalidAccountId(accountId);
		wallet.removeAccountAt(accountId);

		accountId = wallet.nextAccountId();
		expectRevertInvalidAccountId(accountId);
		wallet.removeAccountAt(accountId);
	}

	function test_removeAccountAt() public virtual impersonate(signer.addr) {
		address[] memory accounts = new address[](numSubAccounts * 2);
		for (uint256 i; i < accounts.length; ++i) {
			if (i < numSubAccounts) {
				accounts[i] = subAccounts[i].addr;
			} else {
				wallet.addAccount((accounts[i] = makeAddr(string.concat("NewSubAccount", vm.toString(i)))));
			}
		}

		address[] memory allAccounts = wallet.getAccountsList();
		for (uint256 i = allAccounts.length - 1; i > 0; --i) {
			wallet.removeAccountAt(i);
			assertEq(wallet.getAccountAt(i), address(0));
			assertFalse(wallet.isAuthorized(accounts[i - 1]));
		}

		assertEq(wallet.getAccountsLength(), 1);
		assertEq(wallet.nextAccountId(), allAccounts.length);
	}

	function test_transferOwnership_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorizedOwner();
		wallet.transferOwnership(invalidSigner.addr);
	}

	function test_transferOwnership_revertsWithInvalidAccount() public virtual impersonate(signer.addr) {
		expectRevertInvalidNewOwner();
		wallet.transferOwnership(address(0));
	}

	function test_transferOwnership() public virtual impersonate(signer.addr) {
		account = makeAddr("NewOwner");

		expectEmitOwnershipTransferred(signer.addr, account);
		expectEmitAccountAdded(0, account);

		wallet.transferOwnership(account);

		assertEq(wallet.owner(), account);
		assertEq(wallet.getAccountAt(0), account);
		assertTrue(wallet.isAuthorized(account));
	}
}
