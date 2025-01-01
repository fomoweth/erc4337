// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {Constants} from "./Constants.sol";

abstract contract Deployers is Constants {
	SmartWalletFactory internal factory;
	SmartWallet internal implementation;

	function deployImplementationAndFactory() internal virtual {
		label(address(implementation = new SmartWallet()), "SmartWallet Implementation");
		label(address(factory = new SmartWalletFactory(address(implementation))), "SmartWalletFactory");
	}

	function label(address target, string memory name) internal virtual {
		if (target != address(0) && bytes10(bytes(vm.getLabel(target))) != UNLABELED_PREFIX) vm.label(target, name);
	}
}
