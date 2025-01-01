// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {Constants} from "./Constants.sol";
import {Errors} from "./Errors.sol";
import {Events} from "./Events.sol";
import {Random} from "./Random.sol";

abstract contract BaseTest is Test, Constants, Errors, Events, Random {
	string internal constant network = "ethereum";
	uint256 internal forkId;
	uint256 internal snapshotId = MAX_UINT256;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	function fork() internal virtual {
		uint256 forkBlockNumber = vm.envOr("FORK_BLOCK_ETHEREUM", uint256(0));
		if (forkBlockNumber != 0) {
			forkId = vm.createSelectFork(vm.rpcUrl(network), forkBlockNumber);
		} else {
			forkId = vm.createSelectFork(vm.rpcUrl(network));
		}

		vm.chainId(ETHEREUM_CHAIN_ID);
	}

	function revertToState() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function revertToStateAndDelete() internal virtual {
		if (snapshotId != MAX_UINT256) vm.revertToStateAndDelete(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function advanceBlock(uint256 blocks) internal virtual {
		vm.roll(vm.getBlockNumber() + blocks);
		vm.warp(vm.getBlockTimestamp() + blocks * SECONDS_PER_BLOCK);
	}

	function advanceTime(uint256 time) internal virtual {
		vm.warp(vm.getBlockTimestamp() + time);
		vm.roll(vm.getBlockNumber() + time / SECONDS_PER_BLOCK);
	}

	function checkImplementationSlot(address proxy, address implementation) internal view virtual {
		assertEq(bytes32ToAddress(vm.load(proxy, IMPLEMENTATION_SLOT)), implementation);
	}

	function checkLastRevisionSlot(address proxy, uint256 revision) internal view virtual {
		assertEq(uint256(vm.load(proxy, LAST_REVISION_SLOT)), revision);
	}

	function checkWalletAccounts(address walletAddress, address[] memory subAccounts) internal view virtual {
		SmartWallet wallet = SmartWallet(payable(walletAddress));
		address[] memory accounts = wallet.getAccountsList();
		assertEq(accounts.length - 1, subAccounts.length);
		assertEq(accounts[0], wallet.owner());
		assertTrue(wallet.isAuthorized(accounts[0]));

		for (uint256 i; i < subAccounts.length; ++i) {
			assertEq(subAccounts[i], accounts[i + 1]);
			assertTrue(wallet.isAuthorized(subAccounts[i]));
		}
	}

	function label(address target, string memory name) internal virtual {
		if (target != address(0) && bytes10(bytes(vm.getLabel(target))) != UNLABELED_PREFIX) vm.label(target, name);
	}

	function randomSalt(address owner) internal virtual returns (bytes32) {
		uint256 seed;
		while (true) if ((seed = random() >> 160) != 0) break;

		return encodeSalt(owner, seed);
	}

	function encodeSalt(address owner, uint256 seed) internal pure virtual returns (bytes32) {
		return bytes32((uint256(uint160(owner)) << 96) | (seed >> 160));
	}

	function bytes32ToAddress(bytes32 input) internal pure virtual returns (address output) {
		return address(uint160(uint256(input)));
	}

	function addressToBytes32(address input) internal pure virtual returns (bytes32 output) {
		return bytes32(bytes20(input));
	}

	function emptyAccounts() internal pure virtual returns (address[] memory accounts) {
		return new address[](0);
	}

	function emptyData() internal pure virtual returns (bytes calldata data) {
		assembly ("memory-safe") {
			data.offset := 0x00
			data.length := 0x00
		}
	}

	function isContract(address target) internal view virtual returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(iszero(extcodesize(target)))
		}
	}
}
