// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {SmartWallet} from "src/SmartWallet.sol";

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

	function randomSalt(address owner, uint256 seed) internal virtual returns (bytes32) {
		seed = bound((seed >> 160), 1, MAX_UINT96);
		return bytes32((uint256(uint160(owner)) << 96) | seed);
	}

	function randomSalt(address owner) internal virtual returns (bytes32) {
		uint256 seed;
		while (true) if ((seed = random() >> 160) != 0) break;

		return bytes32((uint256(uint160(owner)) << 96) | seed);
	}

	function getSubAccounts(uint256 n) internal virtual returns (address[] memory accounts) {
		accounts = new address[](n);
		for (uint256 i; i < n; ++i) accounts[i] = makeAddr(string.concat("SubAccount #", vm.toString(i)));
	}

	function getEmptyAccounts() internal pure virtual returns (address[] memory accounts) {
		return new address[](0);
	}

	function checkImplementationSlot(address proxy, address implementation) internal view virtual {
		assertEq(bytes32ToAddress(vm.load(proxy, IMPLEMENTATION_SLOT)), implementation);
	}

	function checkLastRevisionSlot(address proxy, uint256 revision) internal view virtual {
		assertEq(uint256(vm.load(proxy, LAST_REVISION_SLOT)), revision);
	}

	function checkWalletAccounts(SmartWallet wallet, address[] memory subAccounts) internal view virtual {
		address[] memory accounts = wallet.getAccountsList();
		assertEq(accounts.length - 1, subAccounts.length);
		assertEq(accounts[0], wallet.owner());
		assertTrue(wallet.isAuthorized(accounts[0]));
		for (uint256 i; i < subAccounts.length; ++i) {
			assertEq(subAccounts[i], accounts[i + 1]);
			assertTrue(wallet.isAuthorized(subAccounts[i]));
		}
	}
}
