// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";

abstract contract Events is CommonBase {
	// UUPSUpgradeable Proxy
	event Upgraded(address indexed implementation);

	// Initializable
	event Initialized(uint64 revision);

	// Ownable
	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	// AccessControl
	event AccountAdded(uint256 indexed index, address indexed account);
	event AccountRemoved(uint256 indexed index, address indexed account);

	function expectEmitUpgraded(address implementation) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Upgraded(implementation);
	}

	function expectEmitInitialized(uint64 revision) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Initialized(revision);
	}

	function expectEmitOwnershipTransferred(address oldOwner, address newOwner) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	function expectEmitAccountAdded(uint256 index, address account) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit AccountAdded(index, account);
	}

	function expectEmitAccountRemoved(uint256 index, address account) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit AccountRemoved(index, account);
	}
}
