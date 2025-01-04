// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "./Ownable.sol";

/// @title Ownable2Step
/// @notice Provides a two-step mechanism to transfer ownership
/// @dev Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol

abstract contract Ownable2Step is Ownable {
	/// keccak256(bytes("OwnershipTransferStarted(address,address)"))
	bytes32 private constant OWNERSHIP_TRANSFER_STARTED_TOPIC =
		0x38d16b8cac22d99fc7c124b9cd0de2d3fa1faef420bfe791d8c362d765e22700;

	/// keccak256(abi.encode(uint256(keccak256("Ownable2Step.storage.pendingOwner.slot")) - 1)) & ~bytes32(uint256(0xff))
	bytes32 private constant PENDING_OWNER_SLOT = 0x4f819a109408be15232ffa81ff2618ae769f5d0d7c6c351666024deeb89cf200;

	function renounceOwnership() public virtual override onlyOwner {
		assembly ("memory-safe") {
			mstore(0x00, 0xa0387940) // NotSupported()
			revert(0x1c, 0x04)
		}
	}

	function transferOwnership(address account) public virtual override onlyOwner {
		_checkNewOwner(account);
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

	function _setPendingOwner(address account) internal virtual {
		assembly ("memory-safe") {
			log3(0x00, 0x00, OWNERSHIP_TRANSFER_STARTED_TOPIC, caller(), account)
			sstore(PENDING_OWNER_SLOT, account)
		}
	}

	function pendingOwner() public view virtual returns (address account) {
		assembly ("memory-safe") {
			account := sload(PENDING_OWNER_SLOT)
		}
	}
}
