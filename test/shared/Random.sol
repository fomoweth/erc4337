// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/test/utils/TestPlus.sol

abstract contract Random {
	uint256 private constant RANDOM_SLOT = 0x53f529123f3c59d26a82e6766910025d94cc7ee55f644a6e5e6dca7f7587d700;

	uint256 private constant PRIVATE_KEY_MAX = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140;

	uint256 private constant LPRNG_MULTIPLIER = 0x100000000000000000000000000000051;

	uint256 private constant LPRNG_MODULO = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43;

	address private constant VM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

	function random() internal virtual returns (uint256 res) {
		assembly ("memory-safe") {
			res := RANDOM_SLOT
			let s := sload(res)
			mstore(0x20, s)
			let r := keccak256(0x20, 0x40)

			// If the storage is uninitialized, initialize it to the keccak256 of the calldata.
			if iszero(s) {
				s := res
				calldatacopy(mload(0x40), 0x00, calldatasize())
				r := keccak256(mload(0x40), calldatasize())
			}

			sstore(res, add(r, 1))

			// Do some biased sampling for more robust tests.
			// prettier-ignore
			for {} 1 {} {
                let y := mulmod(r, LPRNG_MULTIPLIER, LPRNG_MODULO)

                // With a 1/256 chance, randomly set `r` to any of 0,1,2,3.
                if iszero(byte(19, y)) {
                    r := and(byte(11, y), 3)
                    break
                }

                let d := byte(17, y)

                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(s, r)`.
                    let t := or(xor(s, r), sub(0, and(1, d)))

                    // Set `r` to `t` shifted left or right.
                    // prettier-ignore
                    for {} 1 {} {
                        if iszero(and(8, d)) {
                            if iszero(and(16, d)) { t := 1 }
                            if iszero(and(32, d)) {
                                r := add(shl(shl(3, and(byte(7, y), 31)), t), sub(3, and(7, r)))
                                break
                            }
                            r := add(shl(byte(7, y), t), sub(511, and(1023, r)))
                            break
                        }
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        if iszero(and(32, d)) {
                            r := add(shr(shl(3, and(byte(7, y), 31)), t), sub(3, and(7, r)))
                            break
                        }
                        r := add(shr(byte(7, y), t), sub(511, and(1023, r)))
                        break
                    }

                    // With a 1/2 chance, negate `r`.
                    r := xor(sub(0, shr(7, d)), r)
                    break
                }

                // Otherwise, just set `r` to `xor(s, r)`.
                r := xor(s, r)
                break
            }

			res := r
		}
	}

	function randomUnique() internal returns (uint256 result) {
		result = randomUnique("");
	}

	function randomUnique(uint256 groupId) internal returns (uint256 result) {
		result = randomUnique(bytes32(groupId));
	}

	function randomUnique(bytes32 groupId) internal returns (uint256 result) {
		do {
			result = random();
		} while (_markAsGenerated("uint256", groupId, result));
	}

	function randomUniform() internal returns (uint256 res) {
		assembly ("memory-safe") {
			res := RANDOM_SLOT

			// prettier-ignore
			for { let s := sload(res) } 1 {} {
                // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
                if iszero(s) {
                    calldatacopy(mload(0x40), 0x00, calldatasize())
                    s := keccak256(mload(0x40), calldatasize())
                    sstore(res, s)
                    res := s
                    break
                }

                mstore(0x1f, s)
                s := keccak256(0x20, 0x40)
                sstore(res, s)
                res := s
                break
            }
		}
	}

	function randomChance(uint256 n) internal returns (bool res) {
		uint256 r = randomUniform();

		assembly ("memory-safe") {
			res := iszero(mod(r, n))
		}
	}

	function randomPrivateKey() internal returns (uint256 res) {
		res = randomUniform();

		assembly ("memory-safe") {
			// prettier-ignore
			for {} 1 {} {
                if iszero(and(res, 0x10)) {
                    if iszero(and(res, 0x20)) {
                        res := add(and(res, 0xf), 1)
                        break
                    }

                    res := sub(PRIVATE_KEY_MAX, and(res, 0xf))
                    break
                }

                res := shr(1, res)
                break
            }
		}
	}

	function randomNonZeroAddress() internal returns (address result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			result := xor(shl(158, r), and(sub(7, shr(252, r)), r))
			if iszero(shl(96, result)) {
				mstore(0x00, result)
				result := keccak256(0x00, 0x30)
			}
		}
	}

	function randomUniqueNonZeroAddress(uint256 groupId) internal returns (address result) {
		result = randomUniqueNonZeroAddress(bytes32(groupId));
	}

	function randomUniqueNonZeroAddress(bytes32 groupId) internal returns (address result) {
		do {
			result = randomNonZeroAddress();
		} while (_markAsGenerated("address", groupId, uint160(result)));
	}

	function randomUniqueNonZeroAddress() internal returns (address result) {
		result = randomUniqueNonZeroAddress("");
	}

	function cleaned(address a) internal pure returns (address result) {
		assembly ("memory-safe") {
			result := shr(96, shl(96, a))
		}
	}

	function truncateBytes(bytes memory b, uint256 n) internal pure returns (bytes memory result) {
		assembly ("memory-safe") {
			if gt(mload(b), n) {
				mstore(b, n)
			}
			result := b
		}
	}

	function randomBytes() internal returns (bytes memory result) {
		result = randomBytes(false);
	}

	function randomBytesZeroRightPadded() internal returns (bytes memory result) {
		result = randomBytes(true);
	}

	function randomBytes(bool zeroRightPad) internal returns (bytes memory result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			let n := and(r, 0x1ffff)
			let t := shr(24, r)

			// prettier-ignore
			for {} 1 {} {
                // With a 1/256 chance, just return the zero pointer as the result.
                if iszero(and(t, 0xff0)) {
                    result := 0x60
                    break
                }
				
                result := mload(0x40)
                // With a 15/16 chance, set the length to be
                // exponentially distributed in the range [0,255] (inclusive).
                if shr(252, r) { n := shr(and(t, 0x7), byte(5, r)) }
                // Store some fixed word at the start of the string.
                // We want this function to sometimes return duplicates.
                mstore(add(result, 0x20), xor(calldataload(0x00), RANDOM_SLOT))
                // With a 1/2 chance, copy the contract code to the start and end.
                if iszero(and(t, 0x1000)) {
                    // Copy to the start.
                    if iszero(and(t, 0x2000)) { codecopy(result, byte(1, r), codesize()) }
                    // Copy to the end.
                    codecopy(add(result, n), byte(2, r), 0x40)
                }
                // With a 1/16 chance, randomize the start and end.
                if iszero(and(t, 0xf0000)) {
                    let y := mulmod(r, LPRNG_MULTIPLIER, LPRNG_MODULO)
                    mstore(add(result, 0x20), y)
                    mstore(add(result, n), xor(r, y))
                }
                // With a 1/256 chance, make the result entirely zero bytes.
                if iszero(byte(4, r)) { codecopy(result, codesize(), add(n, 0x20)) }
                // Skip the zero-right-padding if not required.
                if iszero(zeroRightPad) {
                    mstore(0x40, add(n, add(0x40, result))) // Allocate memory.
                    mstore(result, n) // Store the length.
                    break
                }
                mstore(add(add(result, 0x20), n), 0) // Zeroize the word after the result.
                mstore(0x40, add(n, add(0x60, result))) // Allocate memory.
                mstore(result, n) // Store the length.
                break
            }
		}
	}

	function randomBytes(uint256 seed) internal pure returns (bytes memory result) {
		assembly ("memory-safe") {
			mstore(0x00, seed)
			let r := keccak256(0x00, 0x20)
			if lt(byte(2, r), 0x20) {
				result := mload(0x40)
				let n := and(r, 0x7f)
				mstore(result, n)
				codecopy(add(result, 0x20), byte(1, r), add(n, 0x40))
				mstore(0x40, add(add(result, 0x40), n))
			}
		}
	}

	function _markAsGenerated(bytes32 typeId, bytes32 groupId, uint256 value) private returns (bool isSet) {
		assembly ("memory-safe") {
			let m := mload(0x40)
			mstore(0x00, value)
			mstore(0x20, groupId)
			mstore(0x40, typeId)
			mstore(0x60, RANDOM_SLOT)
			let s := keccak256(0x00, 0x80)
			isSet := sload(s)
			sstore(s, 1)
			mstore(0x40, m)
			mstore(0x60, 0)
		}
	}

	function _etch(address target, bytes memory bytecode) private {
		assembly ("memory-safe") {
			let m := mload(0x40)
			mstore(m, 0xb4d6c782) // `etch(address,bytes)`.
			mstore(add(m, 0x20), target)
			mstore(add(m, 0x40), 0x40)
			let n := mload(bytecode)
			mstore(add(m, 0x60), n)

			// prettier-ignore
			for { let i := 0 } lt(i, n) { i := add(0x20, i) } {
                mstore(add(add(m, 0x80), i), mload(add(add(bytecode, 0x20), i)))
            }

			pop(call(gas(), VM_ADDRESS, 0, add(m, 0x1c), add(n, 0x64), 0x00, 0x00))
		}
	}
}
