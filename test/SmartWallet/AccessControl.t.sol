// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract AccessControlTest is SmartWalletTestBase {
	address internal account;

	function test_addAccount_revertsIfNotAuthorized() public virtual {
		account = makeAddr("NewSubAccount");

		vm.prank(invalidSigner.addr);
		expectRevertUnauthorizedOwner();
		wallet.addAccount(account);

		for (uint256 i; i < subAccounts.length; ++i) {
			expectRevertUnauthorizedOwner();
			vm.prank(subAccounts[i].addr);
			wallet.addAccount(account);
		}
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

	function test_removeAccountAt_revertsIfNotAuthorized() public virtual {
		uint256 accountId = wallet.nextAccountId();

		vm.prank(signer.addr);
		wallet.addAccount(makeAddr("NewSubAccount"));

		expectRevertUnauthorizedOwner();
		vm.prank(invalidSigner.addr);
		wallet.removeAccountAt(accountId);

		for (uint256 i; i < subAccounts.length; ++i) {
			expectRevertUnauthorizedOwner();
			vm.prank(subAccounts[i].addr);
			wallet.removeAccountAt(accountId);
		}
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

	function test_transferOwnership_revertsIfNotAuthorized() public virtual {
		expectRevertUnauthorizedOwner();
		vm.prank(invalidSigner.addr);
		wallet.transferOwnership(invalidSigner.addr);

		for (uint256 i; i < subAccounts.length; ++i) {
			expectRevertUnauthorizedOwner();
			vm.prank(subAccounts[i].addr);
			wallet.transferOwnership(subAccounts[i].addr);
		}
	}

	function test_transferOwnership_revertsWithInvalidAccount() public virtual impersonate(signer.addr) {
		expectRevertInvalidNewOwner();
		wallet.transferOwnership(address(0));

		expectRevertInvalidNewOwner();
		wallet.transferOwnership(invalidSigner.addr);
	}

	function test_transferOwnership() public virtual impersonate(signer.addr) {
		assertEq(wallet.pendingOwner(), address(0));
		revertToState();

		for (uint256 i; i < subAccounts.length; ++i) {
			account = subAccounts[i].addr;

			expectEmitOwnershipTransferStarted(signer.addr, account);
			wallet.transferOwnership(account);

			assertEq(wallet.pendingOwner(), account);
			assertEq(wallet.owner(), signer.addr);
			revertToState();
		}
	}

	function test_acceptOwnership_revertsIfNotAuthorized() public virtual {
		assertEq(wallet.pendingOwner(), address(0));

		expectRevertUnauthorizedPendingOwner();
		vm.prank(signer.addr);
		wallet.acceptOwnership();

		expectRevertUnauthorizedPendingOwner();
		vm.prank(invalidSigner.addr);
		wallet.acceptOwnership();

		for (uint256 i; i < subAccounts.length; ++i) {
			expectRevertUnauthorizedPendingOwner();
			vm.prank(subAccounts[i].addr);
			wallet.acceptOwnership();
		}
	}

	function test_acceptOwnership() public virtual {
		assertEq(wallet.pendingOwner(), address(0));
		revertToState();

		for (uint256 i; i < subAccounts.length; ++i) {
			account = subAccounts[i].addr;

			expectEmitOwnershipTransferStarted(signer.addr, account);
			vm.prank(signer.addr);
			wallet.transferOwnership(account);

			assertEq(wallet.pendingOwner(), account);
			assertEq(wallet.owner(), signer.addr);

			expectEmitOwnershipTransferred(signer.addr, account);
			expectEmitAccountAdded(0, account);

			vm.prank(account);
			wallet.acceptOwnership();

			assertEq(wallet.pendingOwner(), address(0));
			assertEq(wallet.owner(), account);
			assertEq(wallet.getAccountAt(0), account);
			assertTrue(wallet.isAuthorized(account));
			assertFalse(wallet.isAuthorized(signer.addr));
			revertToState();
		}
	}

	function test_renounceOwnership_revertsWithNotSupported() public virtual impersonate(signer.addr) {
		expectRevertNotSupported();
		wallet.renounceOwnership();
	}
}
