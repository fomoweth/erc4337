// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {BaseTest} from "test/shared/BaseTest.sol";

abstract contract SmartWalletTestBase is BaseTest {
	address payable internal immutable bundler = payable(makeAddr("Bundler"));

	SmartWalletFactory internal factory;
	SmartWallet internal implementation;
	SmartWallet internal wallet;

	Account internal signer;
	Account internal invalidSigner;

	Account[] internal subAccounts;
	address[] internal subAccountAddresses;
	uint256 internal numSubAccounts = 3;

	uint256 internal initialValue = 1 ether;

	function setUp() public virtual {
		fork();

		vm.label(address(ENTRYPOINT), "EntryPoint");
		vm.makePersistent(address(ENTRYPOINT));
		vm.makePersistent(bundler);

		setUpAccounts();
		setUpSmartWalletFactory();
		setUpSmartWallet();
	}

	function setUpSmartWallet() internal virtual {
		setUpSmartWallet("");
	}

	function setUpSmartWallet(string memory name) internal virtual {
		if (bytes(name).length == 0) name = "SmartWallet Proxy";

		bytes32 salt = encodeSalt(signer.addr, SALT_KEY);
		bytes memory params = abi.encode(salt, subAccountAddresses);

		hoax(signer.addr, initialValue);

		wallet = SmartWallet(payable(factory.createAccount{value: initialValue}(params)));
		vm.label(address(wallet), name);
		vm.makePersistent(address(wallet));
	}

	function setUpSmartWalletFactory() internal virtual {
		implementation = new SmartWallet();
		factory = new SmartWalletFactory(address(implementation));

		vm.label(address(implementation), "SmartWallet Implementation");
		vm.label(address(factory), "SmartWalletFactory");
	}

	function setUpAccounts() internal virtual {
		signer = makeAccount("Owner");
		invalidSigner = makeAccount("InvalidOwner");
		setUpSubAccounts();
	}

	function setUpSubAccounts() internal virtual {
		subAccounts = new Account[](numSubAccounts);
		subAccountAddresses = new address[](numSubAccounts);

		for (uint256 i; i < numSubAccounts; ++i) {
			subAccountAddresses[i] = (subAccounts[i] = makeSubAccount(i)).addr;
		}
	}

	function makeSubAccount(uint256 id) internal virtual returns (Account memory account) {
		return makeAccount(string.concat("SubAccount #", vm.toString(id)));
	}

	function makeAccount(string memory name) internal virtual override returns (Account memory account) {
		deal((account = super.makeAccount(name)).addr, 10 ether);
		vm.makePersistent(account.addr);
	}
}
