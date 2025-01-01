// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";

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

	// EntryPoint
	event UserOperationEvent(
		bytes32 indexed userOpHash,
		address indexed sender,
		address indexed paymaster,
		uint256 nonce,
		bool success,
		uint256 actualGasCost,
		uint256 actualGasUsed
	);
	event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);
	event BeforeExecution();

	// StakeManager
	event Deposited(address indexed account, uint256 totalDeposit);
	event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);
	event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec);
	event StakeUnlocked(address indexed account, uint256 withdrawTime);
	event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

	function expectEmit(address implementation) internal virtual {}

	function expectEmitAccountDeployed(
		address wallet,
		address factory,
		address paymaster,
		bytes32 userOpHash
	) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit AccountDeployed(userOpHash, wallet, factory, paymaster);
	}

	function expectEmitUserOperationEvent(
		PackedUserOperation memory userOp,
		bytes32 userOpHash,
		bool success,
		uint256 actualGasCost,
		uint256 actualGasUsed
	) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit UserOperationEvent(
			userOpHash,
			userOp.sender,
			address(uint160(uint256(bytes32(userOp.paymasterAndData)))),
			userOp.nonce,
			success,
			actualGasCost,
			actualGasUsed
		);
	}

	function expectEmitBeforeExecution() internal virtual {
		vm.expectEmit(true, true, true, true);
		emit BeforeExecution();
	}

	function expectEmitDeposited(address wallet, uint256 totalDeposit) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Deposited(wallet, totalDeposit);
	}

	function expectEmitWithdrawn(address wallet, address recipient, uint256 amount) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit Withdrawn(wallet, recipient, amount);
	}

	function expectEmitStakeLocked(address wallet, uint256 totalStaked, uint256 unstakeDelaySec) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit StakeLocked(wallet, totalStaked, unstakeDelaySec);
	}

	function expectEmitStakeUnlocked(address wallet, uint256 withdrawTime) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit StakeUnlocked(wallet, withdrawTime);
	}

	function expectEmitStakeWithdrawn(address wallet, address recipient, uint256 amount) internal virtual {
		vm.expectEmit(true, true, true, true);
		emit StakeWithdrawn(wallet, recipient, amount);
	}

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
