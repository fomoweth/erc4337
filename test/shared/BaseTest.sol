// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";

import {Common} from "./Common.sol";
import {Deployers} from "./Deployers.sol";
import {Errors} from "./Errors.sol";
import {Events} from "./Events.sol";
import {Random} from "./Random.sol";

abstract contract BaseTest is Test, Common, Deployers, Errors, Events, Random {
	string internal constant network = "ethereum";
	uint256 internal forkId;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	function setUp() public virtual {
		fork();

		label(address(ENTRYPOINT), "EntryPoint");
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

	function getDefaultUserOp() internal pure virtual returns (PackedUserOperation memory userOp) {
		userOp = PackedUserOperation({
			sender: address(0),
			nonce: 0,
			initCode: "",
			callData: "",
			accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
			preVerificationGas: 2e6,
			gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
			paymasterAndData: bytes(""),
			signature: abi.encodePacked(hex"41414141")
		});
	}

	function checkImplementationSlot(address proxy, address implementation) internal virtual {
		assertEq(bytes32ToAddress(vm.load(proxy, IMPLEMENTATION_SLOT)), implementation);
	}

	function checkLastRevisionSlot(address proxy, uint256 revision) internal virtual {
		assertEq(uint256(vm.load(proxy, LAST_REVISION_SLOT)), revision);
	}
}
