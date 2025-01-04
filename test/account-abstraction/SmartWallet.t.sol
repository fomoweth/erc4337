// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract SmartWalletTest is SmartWalletTestBase {
	address internal immutable recipient = makeAddr("Recipient");

	uint256 internal depositValue;
	uint256 internal withdrawValue;

	function setUp() public virtual override {
		super.setUp();

		withdrawValue = (depositValue = vm.randomUint(1, 11) * 1 ether) / 2;
		deal(signer.addr, depositValue * 2);
	}

	function setUpAccounts() internal virtual override {
		super.setUpAccounts();
		vm.makePersistent(recipient);
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

	function test_addDeposit_succeedsWithAuthorizedAccounts() public virtual {
		startHoax(signer.addr, depositValue);

		uint256 depositPrior = wallet.getDeposit();
		uint256 depositTotal = depositPrior + depositValue;

		uint256 balancePrior = address(ENTRYPOINT).balance;

		revertToState();

		expectEmitDeposited(address(wallet), depositTotal);
		wallet.addDeposit{value: depositValue}();

		assertEq(wallet.getDeposit(), depositTotal);
		assertEq(address(ENTRYPOINT).balance - balancePrior, depositValue);

		vm.stopPrank();

		revertToState();

		hoax(subAccounts[0].addr, depositValue);

		expectEmitDeposited(address(wallet), depositTotal);
		wallet.addDeposit{value: depositValue}();

		assertEq(wallet.getDeposit(), depositTotal);
		assertEq(address(ENTRYPOINT).balance - balancePrior, depositValue);
	}

	function test_withdrawDepositTo_revertsIfNotAuthorized() public virtual {
		vm.prank(invalidSigner.addr);
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.withdrawDepositTo(recipient, 1 ether);

		vm.prank(address(ENTRYPOINT));
		expectRevertUnauthorized(address(ENTRYPOINT));
		wallet.withdrawDepositTo(recipient, 1 ether);
	}

	function test_withdrawDepositTo_revertsWithInsufficientDeposit() public virtual impersonate(signer.addr) {
		expectRevert();
		wallet.withdrawDepositTo(recipient, withdrawValue);
	}

	function test_withdrawDepositTo_succeedsWithAuthorizedAccounts() public virtual {
		assertEq(recipient.balance, 0);

		startHoax(signer.addr, depositValue);
		wallet.addDeposit{value: depositValue}();

		uint256 depositPrior = wallet.getDeposit();
		uint256 balancePrior = address(ENTRYPOINT).balance;

		revertToState();

		expectEmitWithdrawn(address(wallet), recipient, withdrawValue);
		wallet.withdrawDepositTo(recipient, withdrawValue);

		assertEq(depositPrior - wallet.getDeposit(), withdrawValue);
		assertEq(balancePrior - address(ENTRYPOINT).balance, withdrawValue);
		assertEq(recipient.balance, withdrawValue);

		vm.stopPrank();

		revertToState();

		hoax(subAccounts[0].addr, depositValue);

		expectEmitWithdrawn(address(wallet), recipient, withdrawValue);
		wallet.withdrawDepositTo(recipient, withdrawValue);

		assertEq(depositPrior - wallet.getDeposit(), withdrawValue);
		assertEq(balancePrior - address(ENTRYPOINT).balance, withdrawValue);
		assertEq(recipient.balance, withdrawValue);
	}

	function test_useNonce_revertsIfNotAuthorized() public virtual {
		vm.prank(invalidSigner.addr);
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.useNonce(0);

		vm.prank(address(ENTRYPOINT));
		expectRevertUnauthorized(address(ENTRYPOINT));
		wallet.useNonce(0);
	}

	function test_useNonce() public virtual {
		uint256 nonce = wallet.getNonce();

		revertToState();

		vm.prank(signer.addr);
		wallet.useNonce(0);

		assertEq(wallet.getNonce() - 1, nonce);

		revertToState();

		vm.prank(subAccounts[0].addr);
		wallet.useNonce(0);

		assertEq(wallet.getNonce() - 1, nonce);
	}
}
