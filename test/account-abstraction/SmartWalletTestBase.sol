// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ECDSA} from "src/libraries/ECDSA.sol";
import {PackedUserOperation} from "src/types/PackedUserOperation.sol";
import {SmartWalletFactory} from "src/SmartWalletFactory.sol";
import {SmartWallet} from "src/SmartWallet.sol";

import {BaseTest} from "test/shared/BaseTest.sol";

abstract contract SmartWalletTestBase is BaseTest {
	using ECDSA for bytes32;

	address payable internal immutable bundler = payable(makeAddr("Bundler"));

	SmartWalletFactory internal factory;
	SmartWallet internal implementation;
	SmartWallet internal wallet;

	Account internal signer;
	Account internal invalidSigner;

	Account[] internal subAccounts;
	address[] internal subAccountAddresses;
	uint256 internal numSubAccounts = 3;

	uint256 internal userOpNonce;
	bytes internal userOpCalldata;

	function setUp() public virtual {
		fork();

		vm.label(address(ENTRYPOINT), "EntryPoint");
		vm.label(address(implementation = new SmartWallet()), "SmartWallet Implementation");
		vm.label(address(factory = new SmartWalletFactory(address(implementation))), "SmartWalletFactory");

		signer = makeAccount("Owner");
		invalidSigner = makeAccount("InvalidOwner");
		setUpSubAccounts();

		bytes32 salt = encodeSalt(signer.addr, SALT_KEY);
		bytes memory params = abi.encode(salt, subAccountAddresses);
		uint256 value = 1 ether;

		hoax(signer.addr, value);
		vm.label(
			address(wallet = SmartWallet(payable(factory.createAccount{value: value}(params)))),
			"SmartWallet Proxy"
		);
	}

	function executeUserOps(PackedUserOperation[] memory userOps) internal virtual {
		ENTRYPOINT.handleOps(userOps, bundler);
	}

	function executeUserOps(PackedUserOperation memory userOp) internal virtual {
		PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
		userOps[0] = userOp;
		executeUserOps(userOps);
	}

	function signUserOp(
		PackedUserOperation memory userOp,
		Account memory account
	) internal view returns (bytes memory signature) {
		bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOp);
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(account.key, userOpHash);
		signature = abi.encodePacked(uint8(0), r, s, v);
	}

	function getUserOpWithSignature() internal view returns (PackedUserOperation memory userOp) {
		userOp = getDefaultUserOp();
		userOp.signature = signUserOp(userOp, signer);
	}

	function getDefaultUserOp() internal view virtual returns (PackedUserOperation memory userOp) {
		userOp = PackedUserOperation({
			sender: address(wallet),
			nonce: userOpNonce,
			initCode: emptyData(),
			callData: userOpCalldata,
			accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
			preVerificationGas: 2e6,
			gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
			paymasterAndData: emptyData(),
			signature: emptyData()
		});
	}

	function setUpSubAccounts() public virtual {
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
	}
}
