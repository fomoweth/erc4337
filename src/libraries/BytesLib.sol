// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title BytesLib
/// @notice Library for abi decoding in calldata

library BytesLib {
	uint256 internal constant LENGTH_MASK = 0xffffffff;
	uint256 internal constant LENGTH_MASK_AND_WORD_ALIGN = 0xffffffe0;
	bytes4 internal constant SLICE_OUT_OF_BOUNDS_ERROR = 0x3b99b53d; // SliceOutOfBounds()

	function toAddress(bytes calldata data) internal pure returns (address res) {
		assembly ("memory-safe") {
			if lt(data.length, 0x14) {
				mstore(0x00, SLICE_OUT_OF_BOUNDS_ERROR)
				revert(0x00, 0x04)
			}

			res := shr(0x60, calldataload(data.offset))
		}
	}

	function toAddress(bytes calldata data, uint256 index) internal pure returns (address res) {
		assembly ("memory-safe") {
			if lt(data.length, add(shl(0x05, index), 0x20)) {
				mstore(0x00, SLICE_OUT_OF_BOUNDS_ERROR)
				revert(0x00, 0x04)
			}

			res := calldataload(add(data.offset, shl(0x05, index)))
		}
	}

	function toAddressArray(bytes calldata data, uint256 index) internal pure returns (address[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toUint256(bytes calldata data, uint256 index) internal pure returns (uint256 res) {
		assembly ("memory-safe") {
			if lt(data.length, add(shl(0x05, index), 0x20)) {
				mstore(0x00, SLICE_OUT_OF_BOUNDS_ERROR)
				revert(0x00, 0x04)
			}

			res := calldataload(add(data.offset, shl(0x05, index)))
		}
	}

	function toUint256Array(bytes calldata data, uint256 index) internal pure returns (uint256[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytes4(bytes calldata data) internal pure returns (bytes4 res) {
		assembly ("memory-safe") {
			if lt(data.length, 0x04) {
				mstore(0x00, SLICE_OUT_OF_BOUNDS_ERROR)
				revert(0x00, 0x04)
			}

			res := calldataload(data.offset)
		}
	}

	function toBytes4Array(bytes calldata data, uint256 index) internal pure returns (bytes4[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytes32(bytes calldata data, uint256 index) internal pure returns (bytes32 res) {
		assembly ("memory-safe") {
			if lt(data.length, add(shl(0x05, index), 0x20)) {
				mstore(0x00, SLICE_OUT_OF_BOUNDS_ERROR)
				revert(0x00, 0x04)
			}

			res := calldataload(add(data.offset, shl(0x05, index)))
		}
	}

	function toBytes32Array(bytes calldata data, uint256 index) internal pure returns (bytes32[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytes(bytes calldata data, uint256 index) internal pure returns (bytes calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytesArray(bytes calldata data, uint256 index) internal pure returns (bytes[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toLengthOffset(bytes calldata data, uint256 index) internal pure returns (uint256 length, uint256 offset) {
		assembly ("memory-safe") {
			let lengthPtr := add(data.offset, and(calldataload(add(data.offset, shl(0x05, index))), LENGTH_MASK))
			length := and(calldataload(lengthPtr), LENGTH_MASK)
			offset := add(lengthPtr, 0x20)

			if lt(add(data.length, data.offset), add(length, offset)) {
				mstore(0x00, SLICE_OUT_OF_BOUNDS_ERROR)
				revert(0x00, 0x04)
			}
		}
	}
}
