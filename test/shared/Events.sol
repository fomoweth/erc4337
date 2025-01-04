// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";

abstract contract Events is CommonBase {
	// StakeManager
	event Deposited(address indexed account, uint256 totalDeposit);
	event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

	// ERC-721
	event Transfer(address indexed from, address indexed to, uint256 indexed id);

	// ERC-1155
	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 amount
	);

	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] amounts
	);

	// UUPSUpgradeable Proxy
	event Upgraded(address indexed implementation);

	// Initializable
	event Initialized(uint64 revision);

	// Ownable2Step
	event OwnershipTransferStarted(address indexed oldOwner, address indexed newOwner);
	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	// AccessControl
	event AccountAdded(uint256 indexed index, address indexed account);
	event AccountRemoved(uint256 indexed index, address indexed account);

	function expectEmit(address implementation) internal virtual {}

	function expectEmitTransferERC721(address from, address to, uint256 id) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Transfer(from, to, id);
	}

	function expectEmitTransferSingleERC1155(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount
	) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit TransferSingle(operator, from, to, id, amount);
	}

	function expectEmitTransferBatchERC1155(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit TransferBatch(operator, from, to, ids, amounts);
	}

	function expectEmitDeposited(address wallet, uint256 totalDeposit) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Deposited(wallet, totalDeposit);
	}

	function expectEmitWithdrawn(address wallet, address recipient, uint256 amount) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Withdrawn(wallet, recipient, amount);
	}

	function expectEmitUpgraded(address implementation) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Upgraded(implementation);
	}

	function expectEmitInitialized(uint64 revision) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Initialized(revision);
	}

	function expectEmitOwnershipTransferStarted(address oldOwner, address newOwner) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit OwnershipTransferStarted(oldOwner, newOwner);
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
