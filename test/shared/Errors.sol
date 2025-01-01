// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";

abstract contract Errors is CommonBase {
	error UpgradeFailed();
	error UnauthorizedCallContext();
	error InvalidInitialization();
	error InitializedAlready();
	error InvalidNewOwner();
	error UnauthorizedOwner();
	error Unauthorized(address account);
	error AuthorizedAlready(address account);
	error InvalidAccount();
	error InvalidAccountId(uint256 index);

	function expectRevertUpgradeFailed() internal virtual {
		vm.expectRevert(UpgradeFailed.selector);
	}

	function expectRevertUnauthorizedCallContext() internal virtual {
		vm.expectRevert(UnauthorizedCallContext.selector);
	}

	function expectRevertInitializedAlready() internal virtual {
		vm.expectRevert(InitializedAlready.selector);
	}

	function expectRevertInvalidInitialization() internal virtual {
		vm.expectRevert(InvalidInitialization.selector);
	}

	function expectRevertInvalidNewOwner() internal virtual {
		vm.expectRevert(InvalidNewOwner.selector);
	}

	function expectRevertUnauthorizedOwner() internal virtual {
		vm.expectRevert(UnauthorizedOwner.selector);
	}

	function expectRevertUnauthorized(address account) internal virtual {
		vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, account));
	}

	function expectRevertAuthorizedAlready(address account) internal virtual {
		vm.expectRevert(abi.encodeWithSelector(AuthorizedAlready.selector, account));
	}

	function expectRevertInvalidAccount() internal virtual {
		vm.expectRevert(InvalidAccount.selector);
	}

	function expectRevertInvalidAccountId(uint256 id) internal virtual {
		vm.expectRevert(abi.encodeWithSelector(InvalidAccountId.selector, id));
	}
}
