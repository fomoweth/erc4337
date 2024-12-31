// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ECDSA
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/utils/ECDSA.sol

library ECDSA {
	function recover(bytes32 hash, bytes calldata signature) internal view returns (address signer) {
		assembly ("memory-safe") {
			// prettier-ignore
			for { let ptr := mload(0x40) } 0x01 {
                mstore(0x00, 0x8baa579f) // InvalidSignature()
                revert(0x1c, 0x04)
            } {
                switch signature.length
                case 0x40 {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(0xff, vs), 0x1b))
                    mstore(0x40, calldataload(signature.offset))
                    mstore(0x60, shr(0x01, shl(0x01, vs)))
                }
                case 0x41 {
                    mstore(0x20, byte(0x00, calldataload(add(signature.offset, 0x40))))
                    calldatacopy(0x40, signature.offset, 0x40)
                }
                default { continue }

                mstore(0x00, hash)
                signer := mload(staticcall(gas(), 0x01, 0x00, 0x80, 0x01, 0x20))

                mstore(0x60, 0x00)
                mstore(0x40, ptr)

                if returndatasize() { break }
            }
		}
	}

	function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 digest) {
		assembly ("memory-safe") {
			mstore(0x20, hash)
			mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
			digest := keccak256(0x04, 0x3c)
		}
	}
}
