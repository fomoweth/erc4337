// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommonBase} from "forge-std/Base.sol";

abstract contract Errors is CommonBase {
	// UUPSUpgradeable Proxy
	error UpgradeFailed();
	error UnauthorizedCallContext();

	// Initializable
	error InvalidInitialization();

	// AccessControl & Ownable
	error InitializedAlready();
	error InvalidNewOwner();
	error UnauthorizedOwner();
	error Unauthorized(address account);
	error AuthorizedAlready(address account);
	error InvalidAccount();
	error InvalidAccountId(uint256 index);

	// SmartWalletFactory
	error SaltDoesNotStartWithCaller();
	error SliceOutOfBounds();

	// EntryPoint
	error FailedOp(uint256 opIndex, string reason);
	error FailedOpWithRevert(uint256 opIndex, string reason, bytes inner);
	error PostOpReverted(bytes returnData);

	function expectRevert() internal virtual {
		vm.expectRevert();
	}

	function expectRevert(bytes4 selector) internal virtual {
		vm.expectRevert(selector);
	}

	function expectRevertFailedOp() internal virtual {
		vm.expectRevert(FailedOp.selector);
	}

	function expectRevertFailedOpWithRevert() internal virtual {
		vm.expectRevert(FailedOpWithRevert.selector);
	}

	function expectRevertPostOpReverted() internal virtual {
		vm.expectRevert(PostOpReverted.selector);
	}

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

	function expectRevertSaltDoesNotStartWithCaller() internal virtual {
		vm.expectRevert(SaltDoesNotStartWithCaller.selector);
	}

	function expectRevertSliceOutOfBounds() internal virtual {
		vm.expectRevert(SliceOutOfBounds.selector);
	}
}
