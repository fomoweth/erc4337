// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Ownable
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/auth/Ownable.sol

abstract contract Ownable {
	/// keccak256(bytes("OwnershipTransferred(address,address)"))
	bytes32 private constant OWNERSHIP_TRANSFERRED_TOPIC =
		0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

	/// bytes32(~uint256(uint32(bytes4(keccak256("OWNER_SLOT_NOT")))))
	bytes32 private constant OWNER_SLOT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function owner() public view virtual returns (address account) {
		assembly ("memory-safe") {
			account := sload(OWNER_SLOT)
		}
	}

	function transferOwnership(address account) public virtual onlyOwner {
		_checkNewOwner(account);
		_setOwner(account);
	}

	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}

	function _initializeOwner(address account) internal virtual {
		assembly ("memory-safe") {
			if sload(OWNER_SLOT) {
				mstore(0x00, 0xe7d06772) // InitializedAlready()
				revert(0x1c, 0x04)
			}

			account := shr(0x60, shl(0x60, account))

			sstore(OWNER_SLOT, or(account, shl(0xff, iszero(account))))

			log3(0x00, 0x00, OWNERSHIP_TRANSFERRED_TOPIC, 0x00, account)
		}
	}

	function _setOwner(address account) internal virtual {
		assembly ("memory-safe") {
			account := shr(0x60, shl(0x60, account))

			log3(0x00, 0x00, OWNERSHIP_TRANSFERRED_TOPIC, sload(OWNER_SLOT), account)

			sstore(OWNER_SLOT, or(account, shl(0xff, iszero(account))))
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

	function _checkNewOwner(address account) internal pure virtual {
		assembly ("memory-safe") {
			if iszero(shl(0x60, account)) {
				mstore(0x00, 0x54a56786) // InvalidNewOwner()
				revert(0x1c, 0x04)
			}
		}
	}
}
