// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAccessControl} from "src/interfaces/account/IAccessControl.sol";
import {Ownable2Step} from "./Ownable2Step.sol";

/// @title AccessControl
/// @notice Provides functions to manage accounts for the smart wallet.

abstract contract AccessControl is IAccessControl, Ownable2Step {
	/// keccak256(bytes("AccountAdded(uint256,address)"))
	bytes32 private constant ACCOUNT_ADDED_TOPIC = 0xcdf90f998fb308726a3c0cc206e7170e5ad701ef1666da2ea6642ec5bddade79;

	/// keccak256(bytes("AccountRemoved(uint256,address)"))
	bytes32 private constant ACCOUNT_REMOVED_TOPIC = 0x4674cfbaa07dd61de1508c228fc2c5abd2a1878fbbd4635684fb378676274df4;

	/// keccak256(abi.encode(uint256(keccak256("AccessControl.storage.slot")) - 1)) & ~bytes32(uint256(0xff))
	bytes32 internal constant ACCESS_CONTROL_STORAGE_SLOT =
		0x8d900783fdf1b574be676081264a7bc91515444110d4b5394dbe5d85f73d2000;

	uint256 internal constant NEXT_ID_OFFSET = 0;
	uint256 internal constant ACCOUNTS_OFFSET = 1;
	uint256 internal constant IS_AUTHORIZED_OFFSET = 2;

	modifier onlyAuthorized() {
		bool isAuthorizedCaller = isAuthorized(msg.sender);
		assembly ("memory-safe") {
			if iszero(isAuthorizedCaller) {
				mstore(0x00, shl(0xe0, 0x8e4a23d6)) // Unauthorized(address)
				mstore(0x04, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff))
				revert(0x00, 0x24)
			}
		}
		_;
	}

	function addAccount(address account) public virtual onlyOwner {
		_addAccountAtNextId(account);
	}

	function _addAccountAtNextId(address account) internal virtual {
		assembly ("memory-safe") {
			function deriveMapping(slot, key) -> derivedSlot {
				mstore(0x00, key)
				mstore(0x20, slot)
				derivedSlot := keccak256(0x00, 0x40)
			}

			account := shr(0x60, shl(0x60, account))
			if iszero(account) {
				mstore(0x00, 0x6d187b28) // InvalidAccount()
				revert(0x1c, 0x04)
			}

			let nextIdSlot := deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, NEXT_ID_OFFSET)
			let accountsSlot := deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, ACCOUNTS_OFFSET)
			let isAuthorizedSlot := deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, IS_AUTHORIZED_OFFSET)

			// equivalent to if (storage.isAuthorized[account]) revert AuthorizedAlready(account);
			if sload(deriveMapping(isAuthorizedSlot, account)) {
				mstore(0x00, shl(0xe0, 0xeed275b4)) // AuthorizedAlready(address)
				mstore(0x04, account)
				revert(0x00, 0x24)
			}

			let index := sload(nextIdSlot)
			// equivalent to ++storage.nextId;
			sstore(nextIdSlot, add(index, 0x01))
			// equivalent to storage.accounts[index] = account;
			sstore(deriveMapping(accountsSlot, index), account)
			// equivalent to storage.isAuthorized[account] = true;
			sstore(deriveMapping(isAuthorizedSlot, account), 0x01)

			log3(0x00, 0x00, ACCOUNT_ADDED_TOPIC, index, account)
		}
	}

	function removeAccountAt(uint256 index) public virtual onlyOwner {
		assembly ("memory-safe") {
			function deriveMapping(slot, key) -> derivedSlot {
				mstore(0x00, key)
				mstore(0x20, slot)
				derivedSlot := keccak256(0x00, 0x40)
			}

			// the given index cannot be 0, since the owner's address cannot be removed from accounts list;
			// it can only be replace by the new owner's address when the ownership is being transferred
			if eq(index, 0x00) {
				mstore(0x00, shl(0xe0, 0xce7793a9)) // InvalidAccountId(uint256)
				mstore(0x04, index)
				revert(0x00, 0x24)
			}

			let accountsSlot := deriveMapping(deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, ACCOUNTS_OFFSET), index)

			// equivalent to account = storage.accounts[index];
			let account := sload(accountsSlot)
			if iszero(account) {
				mstore(0x00, shl(0xe0, 0xce7793a9)) // InvalidAccountId(uint256)
				mstore(0x04, index)
				revert(0x00, 0x24)
			}

			// equivalent to delete storage.accounts[index];
			sstore(accountsSlot, 0x00)
			// equivalent to delete storage.isAuthorized[account];
			sstore(deriveMapping(deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, IS_AUTHORIZED_OFFSET), account), 0x00)

			log3(0x00, 0x00, ACCOUNT_REMOVED_TOPIC, index, account)
		}
	}

	function _initializeSubAccounts(address[] calldata subAccounts) internal virtual {
		assembly ("memory-safe") {
			function deriveMapping(slot, key) -> derivedSlot {
				mstore(0x00, key)
				mstore(0x20, slot)
				derivedSlot := keccak256(0x00, 0x40)
			}

			let nextIdSlot := deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, NEXT_ID_OFFSET)
			let accountsSlot := deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, ACCOUNTS_OFFSET)
			let isAuthorizedSlot := deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, IS_AUTHORIZED_OFFSET)

			// the owner's address should added beforehand therefore the value of nextAccountId must be equal to 1
			if xor(sload(nextIdSlot), 0x01) {
				mstore(0x00, 0xe7d06772) // InitializedAlready()
				revert(0x1c, 0x04)
			}

			// prettier-ignore
			for { let i } lt(i, subAccounts.length) { i := add(i, 0x01) } {
				let account := shr(0x60, shl(0x60, calldataload(add(subAccounts.offset, shl(0x05, i)))))
				if iszero(account) {
					mstore(0x00, 0x6d187b28) // InvalidAccount()
					revert(0x1c, 0x04)
				}

				// validate that the account's address at current index is not authorized yet;
				// therefore, every account's address from the given array must be unique and not be equal to the owner's address
				if sload(deriveMapping(isAuthorizedSlot, account)) {
					mstore(0x00, shl(0xe0, 0xeed275b4)) // AuthorizedAlready(address)
					mstore(0x04, account)
					revert(0x00, 0x24)
				}

				// equivalent to storedAccounts.accounts[i + 1] = subAccounts[i];
				sstore(deriveMapping(accountsSlot, add(i, 0x01)), account)
				// equivalent to storedAccounts.isAuthorized[subAccounts[i]] = true;
				sstore(deriveMapping(isAuthorizedSlot, account), 0x01)

				log3(0x00, 0x00, ACCOUNT_ADDED_TOPIC, add(i, 0x01), account)
			}

			// set the value of nextId at the end instead of incrementing it every iteration
			// equivalent to storedAccounts.nextId = subAccounts.length + 1;
			sstore(nextIdSlot, add(subAccounts.length, 0x01))
		}
	}

	function _initializeOwner(address account) internal virtual override {
		super._initializeOwner(account);
		// add the owner's address to the accounts list
		_addAccountAtNextId(account);
	}

	function _setOwner(address account) internal virtual override {
		address oldOwner = owner();
		super._setOwner(account);

		assembly ("memory-safe") {
			function deriveMapping(slot, key) -> derivedSlot {
				mstore(0x00, key)
				mstore(0x20, slot)
				derivedSlot := keccak256(0x00, 0x40)
			}

			// equivalent to storage.accounts[0] = account;
			sstore(deriveMapping(deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, ACCOUNTS_OFFSET), 0x00), account)
			// equivalent to storage.isAuthorized[account] = true;
			sstore(deriveMapping(deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, IS_AUTHORIZED_OFFSET), account), 0x01)
			// equivalent to storage.isAuthorized[oldOwner] = false;
			sstore(deriveMapping(deriveMapping(ACCESS_CONTROL_STORAGE_SLOT, IS_AUTHORIZED_OFFSET), oldOwner), 0x00)

			log3(0x00, 0x00, ACCOUNT_ADDED_TOPIC, 0x00, account)
		}
	}

	function _checkNewOwner(address account) internal view virtual override {
		super._checkNewOwner(account);

		assembly ("memory-safe") {
			mstore(0x00, IS_AUTHORIZED_OFFSET)
			mstore(0x20, ACCESS_CONTROL_STORAGE_SLOT)
			mstore(0x20, keccak256(0x00, 0x40))
			mstore(0x00, account)

			// equivalent to if(!storage.isAuthorized[account]) revert InvalidNewOwner();
			if iszero(sload(keccak256(0x00, 0x40))) {
				mstore(0x00, 0x54a56786) // InvalidNewOwner()
				revert(0x1c, 0x04)
			}
		}
	}

	function getAccountsList() public view virtual returns (address[] memory accounts) {
		unchecked {
			uint256 length = nextAccountId();
			uint256 count;
			address account;

			accounts = new address[](length);

			for (uint256 i; i < length; ++i) {
				// skip if the account's address at i is equal to 0
				if ((account = getAccountAt(i)) == address(0)) continue;
				// push the account's address to the accounts array then increment the count
				accounts[count] = account;
				++count;
			}

			assembly ("memory-safe") {
				// set the length of accounts array if it's not equal to the count
				if xor(length, count) {
					mstore(accounts, count)
				}
			}
		}
	}

	function getAccountsLength() public view virtual returns (uint256 numAccounts) {
		unchecked {
			uint256 length = nextAccountId();
			// increment the value of numAccounts if the account's address at i is not equal to 0
			for (uint256 i; i < length; ++i) if (getAccountAt(i) != address(0)) ++numAccounts;
		}
	}

	function nextAccountId() public view virtual returns (uint256 id) {
		assembly ("memory-safe") {
			mstore(0x00, NEXT_ID_OFFSET)
			mstore(0x20, ACCESS_CONTROL_STORAGE_SLOT)
			// equivalent to id = storage.nextId;
			id := sload(keccak256(0x00, 0x40))
		}
	}

	function getAccountAt(uint256 index) public view virtual returns (address account) {
		assembly ("memory-safe") {
			mstore(0x00, ACCOUNTS_OFFSET)
			mstore(0x20, ACCESS_CONTROL_STORAGE_SLOT)
			mstore(0x20, keccak256(0x00, 0x40))
			mstore(0x00, index)
			// equivalent to account = storage.accounts[index];
			account := sload(keccak256(0x00, 0x40))
		}
	}

	function isAuthorized(address account) public view virtual returns (bool flag) {
		assembly ("memory-safe") {
			mstore(0x00, IS_AUTHORIZED_OFFSET)
			mstore(0x20, ACCESS_CONTROL_STORAGE_SLOT)
			mstore(0x20, keccak256(0x00, 0x40))
			mstore(0x00, shr(0x60, shl(0x60, account)))
			// equivalent to flag = storage.isAuthorized[account];
			flag := sload(keccak256(0x00, 0x40))
		}
	}
}
