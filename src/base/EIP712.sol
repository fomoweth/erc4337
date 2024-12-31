// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title EIP712
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/utils/EIP712.sol

abstract contract EIP712 {
	/// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
	bytes32 internal constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	uint256 private immutable _cachedThis;
	uint256 private immutable _cachedChainId;
	bytes32 private immutable _cachedNameHash;
	bytes32 private immutable _cachedVersionHash;
	bytes32 private immutable _cachedDomainSeparator;

	constructor() {
		_cachedThis = uint256(uint160(address(this)));
		_cachedChainId = block.chainid;

		string memory name;
		string memory version;
		if (!_domainNameAndVersionMayChange()) (name, version) = _domainNameAndVersion();
		bytes32 nameHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(name));
		bytes32 versionHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(version));
		_cachedNameHash = nameHash;
		_cachedVersionHash = versionHash;

		bytes32 separator;
		if (!_domainNameAndVersionMayChange()) {
			assembly ("memory-safe") {
				let ptr := mload(0x40)
				mstore(ptr, DOMAIN_TYPEHASH)
				mstore(add(ptr, 0x20), nameHash)
				mstore(add(ptr, 0x40), versionHash)
				mstore(add(ptr, 0x60), chainid())
				mstore(add(ptr, 0x80), address())
				separator := keccak256(ptr, 0xa0)
			}
		}
		_cachedDomainSeparator = separator;
	}

	function _domainNameAndVersion() internal view virtual returns (string memory name, string memory version);

	function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}

	function _domainSeparator() internal view virtual returns (bytes32 separator) {
		if (_domainNameAndVersionMayChange()) {
			separator = _buildDomainSeparator();
		} else {
			separator = _cachedDomainSeparator;
			if (_cachedDomainSeparatorInvalidated()) separator = _buildDomainSeparator();
		}
	}

	function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
		if (_domainNameAndVersionMayChange()) {
			digest = _buildDomainSeparator();
		} else {
			digest = _cachedDomainSeparator;
			if (_cachedDomainSeparatorInvalidated()) digest = _buildDomainSeparator();
		}

		assembly ("memory-safe") {
			mstore(0x00, 0x1901000000000000)
			mstore(0x1a, digest)
			mstore(0x3a, structHash)
			digest := keccak256(0x18, 0x42)
			mstore(0x3a, 0x00)
		}
	}

	function eip712Domain()
		public
		view
		virtual
		returns (
			bytes1 fields,
			string memory name,
			string memory version,
			uint256 chainId,
			address verifyingContract,
			bytes32 salt,
			uint256[] memory extensions
		)
	{
		fields = hex"0f";
		(name, version) = _domainNameAndVersion();
		chainId = block.chainid;
		verifyingContract = address(this);
		salt = salt;
		extensions = extensions;
	}

	function _buildDomainSeparator() private view returns (bytes32 separator) {
		bytes32 versionHash;
		if (_domainNameAndVersionMayChange()) {
			(string memory name, string memory version) = _domainNameAndVersion();
			separator = keccak256(bytes(name));
			versionHash = keccak256(bytes(version));
		} else {
			separator = _cachedNameHash;
			versionHash = _cachedVersionHash;
		}

		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(ptr, DOMAIN_TYPEHASH)
			mstore(add(ptr, 0x20), separator)
			mstore(add(ptr, 0x40), versionHash)
			mstore(add(ptr, 0x60), chainid())
			mstore(add(ptr, 0x80), address())
			separator := keccak256(ptr, 0xa0)
		}
	}

	function _cachedDomainSeparatorInvalidated() private view returns (bool flag) {
		uint256 cachedChainId = _cachedChainId;
		uint256 cachedThis = _cachedThis;
		assembly ("memory-safe") {
			flag := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
		}
	}
}
