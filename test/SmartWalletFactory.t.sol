// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {BaseTest} from "test/shared/BaseTest.sol";

contract SmartWalletFactoryTest is BaseTest {
	SmartWalletFactory internal factory;

	address internal implementation;

	address[] internal subAccounts;
	uint256 internal numSubAccounts = 3;

	function setUp() public virtual {
		fork();

		vm.label((implementation = address(new SmartWallet())), "SmartWallet Implementation");
		vm.label(address(factory = new SmartWalletFactory(implementation)), "SmartWalletFactory");

		for (uint256 i; i < numSubAccounts; ++i) {
			subAccounts.push(makeAddr(string.concat("SubAccount #", vm.toString(i))));
		}
	}

	function test_createAccount_revertsWithInvalidParameters() public virtual {
		expectRevertSliceOutOfBounds();
		factory.createAccount(emptyData());

		expectRevertSaltDoesNotStartWithCaller();
		factory.createAccount(abi.encode(bytes32(0), subAccounts));

		expectRevertSaltDoesNotStartWithCaller();
		factory.createAccount(abi.encode(randomSalt(subAccounts[0]), subAccounts));
	}

	function test_createAccountWithSubAccounts(uint256 seed) public virtual {
		uint256 value = vm.randomUint(0, 100 ether);
		bytes32 salt = encodeSalt(address(this), seed);
		bytes memory params = abi.encode(salt, subAccounts);

		expectEmitOwnershipTransferred(address(0), address(this));
		expectEmitAccountAdded(0, address(this));
		for (uint256 i; i < subAccounts.length; ++i) expectEmitAccountAdded(i + 1, subAccounts[i]);
		expectEmitInitialized(1);

		address predicted = factory.computeAddress(salt);
		address wallet = factory.createAccount{value: value}(params);
		assertEq(wallet, predicted);
		assertEq(wallet.balance, value);

		checkImplementationSlot(wallet, implementation);
		checkLastRevisionSlot(wallet, 1);
		checkWalletAccounts(wallet, subAccounts);
	}

	function test_createAccountWithoutSubAccounts(uint256 seed) public virtual {
		uint256 value = vm.randomUint(0, 100 ether);
		bytes32 salt = encodeSalt(address(this), seed);
		bytes memory params = abi.encode(salt, emptyAccounts());

		expectEmitOwnershipTransferred(address(0), address(this));
		expectEmitAccountAdded(0, address(this));
		expectEmitInitialized(1);

		address predicted = factory.computeAddress(salt);
		address wallet = factory.createAccount{value: value}(params);
		assertEq(wallet, predicted);
		assertEq(wallet.balance, value);

		checkImplementationSlot(wallet, implementation);
		checkLastRevisionSlot(wallet, 1);
		checkWalletAccounts(wallet, emptyAccounts());
	}

	function test_createAccountWithSameSalt() public virtual {
		uint256 initialValue = vm.randomUint(0, 100 ether);
		uint256 finalValue = vm.randomUint(0, 100 ether);

		bytes32 salt = randomSalt(address(this));
		bytes memory params = abi.encode(salt, subAccounts);

		address predicted = factory.computeAddress(salt);
		address wallet = factory.createAccount{value: initialValue}(params);

		checkImplementationSlot(wallet, implementation);
		checkLastRevisionSlot(wallet, 1);
		checkWalletAccounts(wallet, subAccounts);

		assertEq(wallet, predicted);
		assertEq(wallet.balance, initialValue);
		assertEq(factory.createAccount{value: finalValue}(params), wallet);
		assertEq(factory.createAccount(params), wallet);
		assertEq(wallet.balance, initialValue + finalValue);
	}
}
