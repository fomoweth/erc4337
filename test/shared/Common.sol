// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {Constants} from "./Constants.sol";
import {Random} from "./Random.sol";

abstract contract Common is Constants {
	uint256 internal snapshotId = MAX_UINT256;

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

	function isContract(address target) internal view returns (bool flag) {
		assembly ("memory-safe") {
			flag := iszero(iszero(extcodesize(target)))
		}
	}

	function bytes32ToAddress(bytes32 input) internal pure returns (address output) {
		return address(uint160(uint256(input)));
	}

	function addressToBytes32(address input) internal pure returns (bytes32 output) {
		return bytes32(bytes20(input));
	}
}
