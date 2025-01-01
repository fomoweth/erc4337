// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {BaseTest} from "test/shared/BaseTest.sol";

contract SmartWalletFactoryTest is BaseTest {
	address[] internal subAccounts;

	function setUp() public virtual override {
		super.setUp();

		deployImplementationAndFactory();

		subAccounts = getSubAccounts(3);
		assertEq(subAccounts.length, 3);
	}

	function test_createAccount_revertsWithInvalidParameters() public virtual {
		bytes32 salt;
		bytes memory params;

		expectRevertSliceOutOfBounds();
		factory.createAccount(params);

		expectRevertSaltDoesNotStartWithCaller();
		params = abi.encode(salt, subAccounts);
		factory.createAccount(params);

		expectRevertSaltDoesNotStartWithCaller();
		params = abi.encode((salt = randomSalt(subAccounts[0])), subAccounts);
		factory.createAccount(params);
	}

	function test_createAccountWithSubAccounts(uint256 seed) public virtual {
		uint256 value = vm.randomUint(0, 100 ether);
		bytes32 salt = randomSalt(address(this), seed);
		bytes memory params = abi.encode(salt, subAccounts);

		expectEmitOwnershipTransferred(address(0), address(this));
		expectEmitAccountAdded(0, address(this));
		for (uint256 i; i < subAccounts.length; ++i) expectEmitAccountAdded(i + 1, subAccounts[i]);
		expectEmitInitialized(1);

		address predicted = factory.computeAddress(salt);
		address wallet = factory.createAccount{value: value}(params);
		assertEq(wallet, predicted);
		assertEq(wallet.balance, value);

		checkImplementationSlot(wallet, address(implementation));
		checkLastRevisionSlot(wallet, 1);
		checkWalletAccounts(SmartWallet(payable(wallet)), subAccounts);
	}

	function test_createAccountWithoutSubAccounts(uint256 seed) public virtual {
		uint256 value = vm.randomUint(0, 100 ether);
		bytes32 salt = randomSalt(address(this), seed);
		bytes memory params = abi.encode(salt, getEmptyAccounts());

		expectEmitOwnershipTransferred(address(0), address(this));
		expectEmitAccountAdded(0, address(this));
		expectEmitInitialized(1);

		address predicted = factory.computeAddress(salt);
		address wallet = factory.createAccount{value: value}(params);
		assertEq(wallet, predicted);
		assertEq(wallet.balance, value);

		checkImplementationSlot(wallet, address(implementation));
		checkLastRevisionSlot(wallet, 1);
		checkWalletAccounts(SmartWallet(payable(wallet)), getEmptyAccounts());
	}

	function test_createAccountWithSameSalt() public virtual {
		uint256 initialValue = 10 ether;
		uint256 finalValue = 10 ether;

		bytes32 salt = randomSalt(address(this));
		bytes memory params = abi.encode(salt, subAccounts);

		address predicted = factory.computeAddress(salt);
		address wallet = factory.createAccount{value: initialValue}(params);

		checkImplementationSlot(wallet, address(implementation));
		checkLastRevisionSlot(wallet, 1);
		checkWalletAccounts(SmartWallet(payable(wallet)), subAccounts);

		assertEq(wallet, predicted);
		assertEq(wallet.balance, initialValue);
		assertEq(factory.createAccount{value: finalValue}(params), wallet);
		assertEq(factory.createAccount(params), wallet);
		assertEq(wallet.balance, initialValue + finalValue);
	}
}
