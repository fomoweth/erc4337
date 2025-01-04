// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IOwnable2Step} from "src/interfaces/wallet/IOwnable2Step.sol";

/// @title Ownable2Step
/// @notice Provides a two-step mechanism to transfer ownership
/// @dev Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol

abstract contract Ownable2Step is IOwnable2Step {
	/// keccak256(bytes("OwnershipTransferStarted(address,address)"))
	bytes32 private constant OWNERSHIP_TRANSFER_STARTED_TOPIC =
		0x38d16b8cac22d99fc7c124b9cd0de2d3fa1faef420bfe791d8c362d765e22700;

	/// keccak256(bytes("OwnershipTransferred(address,address)"))
	bytes32 private constant OWNERSHIP_TRANSFERRED_TOPIC =
		0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

	/// keccak256(abi.encode(uint256(keccak256("Ownable2Step.owner.slot")) - 1)) & ~bytes32(uint256(0xff))
	bytes32 private constant OWNER_SLOT = 0x3fa45d927ff4c873316a7bfb6756a11fe52a4428654944d61aa65f47689eb100;

	/// keccak256(abi.encode(uint256(keccak256("Ownable2Step.pendingOwner.slot")) - 1)) & ~bytes32(uint256(0xff))
	bytes32 private constant PENDING_OWNER_SLOT = 0x4f819a109408be15232ffa81ff2618ae769f5d0d7c6c351666024deeb89cf200;

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function transferOwnership(address account) public virtual onlyOwner {
		_checkNewPendingOwner(account);
		_setPendingOwner(account);
	}

	function acceptOwnership() public virtual {
		assembly ("memory-safe") {
			if xor(caller(), sload(PENDING_OWNER_SLOT)) {
				mstore(0x00, 0x99a86eed) // UnauthorizedPendingOwner()
				revert(0x1c, 0x04)
			}

			sstore(PENDING_OWNER_SLOT, 0x00)
		}

		_setOwner(msg.sender);
	}

	function _initializeOwner(address account) internal virtual {
		assembly ("memory-safe") {
			if sload(OWNER_SLOT) {
				mstore(0x00, 0xe7d06772) // InitializedAlready()
				revert(0x1c, 0x04)
			}

			account := shr(0x60, shl(0x60, account))
			if iszero(account) {
				mstore(0x00, 0x54a56786) // InvalidNewOwner()
				revert(0x1c, 0x04)
			}

			log3(0x00, 0x00, OWNERSHIP_TRANSFERRED_TOPIC, 0x00, account)
			sstore(OWNER_SLOT, account)
		}
	}

	function _setOwner(address account) internal virtual {
		assembly ("memory-safe") {
			account := shr(0x60, shl(0x60, account))
			log3(0x00, 0x00, OWNERSHIP_TRANSFERRED_TOPIC, sload(OWNER_SLOT), account)
			sstore(OWNER_SLOT, account)
		}
	}

	function _setPendingOwner(address account) internal virtual {
		assembly ("memory-safe") {
			log3(0x00, 0x00, OWNERSHIP_TRANSFER_STARTED_TOPIC, sload(OWNER_SLOT), account)
			sstore(PENDING_OWNER_SLOT, account)
		}
	}

	function owner() public view virtual returns (address account) {
		assembly ("memory-safe") {
			account := sload(OWNER_SLOT)
		}
	}

	function pendingOwner() public view virtual returns (address account) {
		assembly ("memory-safe") {
			account := sload(PENDING_OWNER_SLOT)
		}
	}

	function _checkOwner() internal view virtual {
		assembly ("memory-safe") {
			if xor(caller(), sload(OWNER_SLOT)) {
				mstore(0x00, 0xde271cf5) // UnauthorizedOwner()
				revert(0x1c, 0x04)
			}
		}
	}

	function _checkNewPendingOwner(address account) internal view virtual {
		assembly ("memory-safe") {
			account := shr(0x60, shl(0x60, account))
			if iszero(account) {
				mstore(0x00, 0x9f2b7601) // InvalidNewPendingOwner()
				revert(0x1c, 0x04)
			}
		}
	}
}
