// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ECDSA} from "src/libraries/ECDSA.sol";
import {Call} from "src/types/Call.sol";
import {PackedUserOperation} from "src/types/PackedUserOperation.sol";

import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract UserOperationTest is SmartWalletTestBase {
	using ECDSA for bytes32;

	bytes4 internal constant ALLOW_SELECTOR = 0x110496e5;
	bytes4 internal constant APPROVE_SELECTOR = 0x095ea7b3;
	bytes4 internal constant INVOKE_SELECTOR = 0x555029a6;
	bytes4 internal constant EXECUTE_SELECTOR = 0xb61d27f6;

	address internal constant BULKER = 0xa397a8C2086C554B531c02E29f3291c9704B00c7;
	address internal constant cUSDCv3 = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;

	uint256 internal userOpNonce;
	bytes internal userOpCalldata;

	function test_validateUserOp_revertsIfNotAuthorized() public virtual {
		vm.prank(invalidSigner.addr);
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.validateUserOp(getDefaultUserOp(), bytes32(0), 0);

		vm.prank(signer.addr);
		expectRevertUnauthorized(signer.addr);
		wallet.validateUserOp(getDefaultUserOp(), bytes32(0), 0);

		vm.prank(subAccounts[0].addr);
		expectRevertUnauthorized(subAccounts[0].addr);
		wallet.validateUserOp(getDefaultUserOp(), bytes32(0), 0);
	}

	function test_validateUserOp() public virtual {
		uint256 callValue = 10 ether;
		deal(signer.addr, callValue);
		vm.startPrank(signer.addr);

		bytes32[] memory actions = new bytes32[](1);
		actions[0] = "ACTION_SUPPLY_NATIVE_TOKEN";

		bytes[] memory data = new bytes[](1);
		data[0] = abi.encode(cUSDCv3, address(wallet), callValue);

		bytes memory callData = abi.encodeWithSelector(INVOKE_SELECTOR, actions, data);

		userOpNonce = 4337;
		userOpCalldata = abi.encodeWithSelector(EXECUTE_SELECTOR, BULKER, callValue, callData);

		PackedUserOperation memory userOp = getDefaultUserOp();
		bytes32 userOpHash = keccak256(
			abi.encode(
				keccak256(
					abi.encode(
						userOp.sender,
						userOp.nonce,
						keccak256(userOp.initCode),
						keccak256(userOp.callData),
						userOp.accountGasLimits,
						userOp.preVerificationGas,
						userOp.gasFees,
						keccak256(userOp.paymasterAndData)
					)
				),
				ENTRYPOINT,
				block.chainid
			)
		);

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.key, userOpHash.toEthSignedMessageHash());
		userOp.signature = abi.encodePacked(r, s, v);

		uint256 epBalance = address(ENTRYPOINT).balance;
		uint256 missingAccountFunds = 123;

		expectRevertUnauthorized(signer.addr);
		wallet.validateUserOp(userOp, userOpHash, missingAccountFunds);

		vm.stopPrank();
		vm.startPrank(address(ENTRYPOINT));

		assertEq(wallet.validateUserOp(userOp, userOpHash, missingAccountFunds), VALIDATION_SUCCESS);
		assertEq(address(ENTRYPOINT).balance - epBalance, missingAccountFunds);

		userOp.signature = abi.encodePacked(r, bytes32(uint256(s) ^ 1), v);

		assertEq(wallet.validateUserOp(userOp, userOpHash, missingAccountFunds), VALIDATION_FAILED);
		assertEq(address(ENTRYPOINT).balance - epBalance, missingAccountFunds * 2);

		vm.stopPrank();
	}

	function test_isValidSignature() public virtual {
		uint256 callValue = 10 ether;

		bytes32[] memory actions = new bytes32[](1);
		actions[0] = "ACTION_SUPPLY_NATIVE_TOKEN";

		bytes[] memory data = new bytes[](1);
		data[0] = abi.encode(cUSDCv3, address(wallet), callValue);

		bytes memory callData = abi.encodeWithSelector(INVOKE_SELECTOR, actions, data);

		userOpNonce = 4337;
		userOpCalldata = abi.encodeWithSelector(EXECUTE_SELECTOR, BULKER, callValue, callData);

		PackedUserOperation memory userOp = getDefaultUserOp();
		bytes32 userOpHash = keccak256(
			abi.encode(
				keccak256(
					abi.encode(
						userOp.sender,
						userOp.nonce,
						keccak256(userOp.initCode),
						keccak256(userOp.callData),
						userOp.accountGasLimits,
						userOp.preVerificationGas,
						userOp.gasFees,
						keccak256(userOp.paymasterAndData)
					)
				),
				ENTRYPOINT,
				block.chainid
			)
		);
		bytes32 hash = ECDSA.toEthSignedMessageHash(userOpHash);

		revertToState();

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.key, hash);
		userOp.signature = abi.encodePacked(r, s, v);

		assertEq(wallet.isValidSignature(hash, userOp.signature), ERC1271_MAGIC_VALUE);

		for (uint256 i; i < subAccounts.length; ++i) {
			revertToState();

			(v, r, s) = vm.sign(subAccounts[i].key, hash);
			userOp.signature = abi.encodePacked(r, s, v);

			assertEq(wallet.isValidSignature(hash, userOp.signature), ERC1271_MAGIC_VALUE);
		}

		revertToState();

		(v, r, s) = vm.sign(invalidSigner.key, hash);
		userOp.signature = abi.encodePacked(r, s, v);

		assertEq(wallet.isValidSignature(hash, userOp.signature), ERC1271_INVALID);
	}

	function test_execute_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		expectRevertUnauthorized(invalidSigner.addr);
		wallet.execute(address(0), 0, emptyBytes());
	}

	function test_execute_revertsWithInsufficientCallValue() public virtual impersonate(signer.addr) {
		uint256 callValue = 10 ether;
		deal(signer.addr, callValue);

		expectRevert();
		wallet.execute(WSTETH.toAddress(), callValue, emptyBytes());
	}

	function test_execute() public virtual impersonate(signer.addr) {
		assertEq(WSTETH.balanceOf(address(wallet)), 0);

		uint256 callValue = 10 ether;
		deal(signer.addr, callValue);

		wallet.execute{value: callValue}(WSTETH.toAddress(), callValue, emptyBytes());

		assertGt(WSTETH.balanceOf(address(wallet)), 0);
	}

	function test_executeBatch_revertsIfNotAuthorized() public virtual impersonate(invalidSigner.addr) {
		Call[] memory calls = new Call[](1);
		calls[0] = Call({target: address(0), value: 0, data: emptyBytes()});

		expectRevertUnauthorized(invalidSigner.addr);
		wallet.executeBatch(calls);
	}

	function test_executeBatch() public virtual {
		uint256 callValue = 10 ether;
		uint256 supplyAmount = 1000 ether;
		uint256 borrowAmount = 10000 * 1e6;

		deal(signer.addr, callValue);
		deal(LINK.toAddress(), address(wallet), supplyAmount);
		deal(UNI.toAddress(), address(wallet), supplyAmount);

		assertEq(LINK.balanceOf(address(wallet)), supplyAmount);
		assertEq(UNI.balanceOf(address(wallet)), supplyAmount);
		assertEq(USDC.balanceOf(address(wallet)), 0);

		bytes32[] memory actions = new bytes32[](4);
		actions[0] = "ACTION_SUPPLY_NATIVE_TOKEN";
		actions[1] = "ACTION_SUPPLY_ASSET";
		actions[2] = "ACTION_SUPPLY_ASSET";
		actions[3] = "ACTION_WITHDRAW_ASSET";

		bytes[] memory data = new bytes[](4);
		data[0] = abi.encode(cUSDCv3, address(wallet), callValue);
		data[1] = abi.encode(cUSDCv3, address(wallet), LINK, supplyAmount);
		data[2] = abi.encode(cUSDCv3, address(wallet), UNI, supplyAmount);
		data[3] = abi.encode(cUSDCv3, address(wallet), USDC, borrowAmount);

		Call[] memory calls = new Call[](4);
		calls[0] = Call({
			target: LINK.toAddress(),
			value: 0,
			data: abi.encodeWithSelector(APPROVE_SELECTOR, cUSDCv3, MAX_UINT256)
		});
		calls[1] = Call({
			target: UNI.toAddress(),
			value: 0,
			data: abi.encodeWithSelector(APPROVE_SELECTOR, cUSDCv3, MAX_UINT256)
		});
		calls[2] = Call({target: cUSDCv3, value: 0, data: abi.encodeWithSelector(ALLOW_SELECTOR, BULKER, true)});
		calls[3] = Call({
			target: BULKER,
			value: callValue,
			data: abi.encodeWithSelector(INVOKE_SELECTOR, actions, data)
		});

		revertToState();

		vm.prank(signer.addr);

		wallet.executeBatch{value: callValue}(calls);

		assertEq(WETH.balanceOf(address(wallet)), 0);
		assertEq(LINK.balanceOf(address(wallet)), 0);
		assertEq(UNI.balanceOf(address(wallet)), 0);
		assertEq(USDC.balanceOf(address(wallet)), 10000 * 1e6);

		for (uint256 i; i < subAccounts.length; ++i) {
			revertToState();

			deal(subAccounts[i].addr, callValue);
			vm.prank(subAccounts[i].addr);

			wallet.executeBatch{value: callValue}(calls);

			assertEq(WETH.balanceOf(address(wallet)), 0);
			assertEq(LINK.balanceOf(address(wallet)), 0);
			assertEq(UNI.balanceOf(address(wallet)), 0);
			assertEq(USDC.balanceOf(address(wallet)), 10000 * 1e6);
		}
	}

	function getDefaultUserOp() internal view virtual returns (PackedUserOperation memory userOp) {
		userOp = PackedUserOperation({
			sender: address(wallet),
			nonce: userOpNonce,
			initCode: emptyBytes(),
			callData: userOpCalldata,
			accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
			preVerificationGas: 2e6,
			gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
			paymasterAndData: emptyBytes(),
			signature: emptyBytes()
		});
	}
}
