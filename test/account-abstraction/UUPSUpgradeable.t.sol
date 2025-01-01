// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BytesLib} from "src/libraries/BytesLib.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract UUPSUpgradeableTest is SmartWalletTestBase {
	address internal implementationV2;
	SmartWalletV2 internal walletV2;

	function setUp() public virtual override {
		super.setUp();

		vm.label((implementationV2 = address(new SmartWalletV2())), "SmartWalletV2 Implementation");
	}

	function test_onlyProxyGuard() public virtual {
		assertEq(implementation.proxiableUUID(), IMPLEMENTATION_SLOT);
		expectRevertUnauthorizedCallContext();
		wallet.proxiableUUID();
	}

	function test_notDelegatedGuard() public virtual {
		expectRevertUnauthorizedCallContext();
		implementation.upgradeToAndCall(address(1), emptyData());
	}

	function test_upgradeToAndCall_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorizedOwner();
		wallet.upgradeToAndCall(implementationV2, emptyData());
	}

	function test_upgradeToAndCall_revertsWithInvalidImplementation() public virtual impersonate(signer.addr) {
		expectRevertUpgradeFailed();
		wallet.upgradeToAndCall(address(0), emptyData());

		expectRevertUpgradeFailed();
		wallet.upgradeToAndCall(address(factory), emptyData());
	}

	function test_upgradeToAndCall() public virtual impersonate(signer.addr) {
		uint256 numAccounts = wallet.getAccountsLength();

		address[] memory newSubAccounts = new address[](3);
		newSubAccounts[0] = makeAddr("NewSubAccount #0");
		newSubAccounts[1] = makeAddr("NewSubAccount #1");
		newSubAccounts[2] = makeAddr("NewSubAccount #2");

		bytes memory params = abi.encode(new address[](0));
		bytes memory callData = abi.encodeWithSelector(0x439fab91, params); // initialize(bytes)

		revertToState();

		expectEmitUpgraded(implementationV2);
		wallet.upgradeToAndCall(implementationV2, callData);

		checkImplementationSlot(address(wallet), implementationV2);
		checkLastRevisionSlot(address(wallet), 2);
		assertEq(wallet.getAccountsLength(), numAccounts);

		revertToState();

		params = abi.encode(newSubAccounts);
		callData = abi.encodeWithSelector(0x439fab91, params); // initialize(bytes)

		expectEmitUpgraded(implementationV2);
		wallet.upgradeToAndCall(implementationV2, callData);

		checkImplementationSlot(address(wallet), implementationV2);
		checkLastRevisionSlot(address(wallet), 2);
		assertEq(wallet.getAccountsLength(), numAccounts + 3);
	}
}

contract SmartWalletV2 is SmartWallet {
	using BytesLib for bytes;

	error EmptyAccounts();
	error InvalidOwner();
	error InvalidOwnerIndex();

	function initialize(bytes calldata data) external virtual override initializer {
		if (getAccountsLength() == 0) revert EmptyAccounts();
		if (owner() == address(0) || owner() == address(1)) revert InvalidOwner();
		if (getAccountAt(0) != owner()) revert InvalidOwnerIndex();

		address[] calldata newSubAccounts = data.toAddressArray(0);
		uint256 length = newSubAccounts.length;

		for (uint256 i; i < length; ++i) {
			_addAccountAtNextId(newSubAccounts[i]);
		}
	}

	function REVISION() public pure virtual override returns (uint256) {
		return 0x02;
	}

	function _domainNameAndVersion() internal pure virtual override returns (string memory, string memory) {
		return ("Fomo ETH Smart Wallet", "2");
	}
}
