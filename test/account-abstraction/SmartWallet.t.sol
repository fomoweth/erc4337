// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2 as console} from "forge-std/Test.sol";

import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet, Call} from "src/SmartWallet.sol";

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

	function test_executeUserOp_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.executeUserOp(getDefaultUserOp(), bytes32(0));
	}

	function test_executeUserOp() internal virtual impersonate(signer.addr) {}

	function test_validateUserOp_revertsIfNotAuthorized() public virtual {
		vm.prank(invalidSigner.addr);
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.validateUserOp(getDefaultUserOp(), bytes32(0), 0);

		vm.prank(signer.addr);
		expectRevertUnauthorized(signer.addr);
		wallet.validateUserOp(getDefaultUserOp(), bytes32(0), 0);

		vm.prank(subAccounts[0].addr);
		expectRevertUnauthorized(subAccounts[0].addr);
		wallet.validateUserOp(getDefaultUserOp(), bytes32(0), 0);
	}

	function test_validateUserOp() internal virtual impersonate(address(ENTRYPOINT)) {}

	function test_execute_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.execute(address(0), 0, emptyData());
	}

	function test_execute() internal virtual impersonate(signer.addr) {}

	function test_executeBatch_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		Call[] memory calls = new Call[](1);
		calls[0] = Call({target: address(0), value: 0, data: emptyData()});

		expectRevertUnauthorized(invalidSigner.addr);
		wallet.executeBatch(calls);
	}

	function test_executeBatch() internal virtual impersonate(signer.addr) {
		Call[] memory calls = new Call[](2);
		calls[0] = Call({target: address(0), value: 0, data: emptyData()});
		calls[1] = Call({target: address(0), value: 0, data: emptyData()});

		wallet.executeBatch(calls);
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
