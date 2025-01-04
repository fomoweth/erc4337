// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MockERC1155} from "test/shared/mocks/MockERC1155.sol";
import {MockERC721} from "test/shared/mocks/MockERC721.sol";
import {SmartWalletTestBase} from "./SmartWalletTestBase.sol";

contract ReceiverTest is SmartWalletTestBase {
	function test_receiverFallbackForERC721() public virtual impersonate(signer.addr) {
		MockERC721 erc721 = new MockERC721("Test NFT", "TNFT");
		erc721.mint(signer.addr, 1);

		expectEmitTransferERC721(signer.addr, address(wallet), 1);
		erc721.safeTransferFrom(signer.addr, address(wallet), 1);
	}

	function test_receiverFallbackForERC1155() public virtual impersonate(signer.addr) {
		MockERC1155 erc1155 = new MockERC1155();
		erc1155.mint(signer.addr, 1, 1, emptyData());

		expectEmitTransferSingleERC1155(signer.addr, signer.addr, address(wallet), 1, 1);
		erc1155.safeTransferFrom(signer.addr, address(wallet), 1, 1, emptyData());
	}

	function test_receiverFallbackForERC1155Batch() public virtual impersonate(signer.addr) {
		MockERC1155 erc1155 = new MockERC1155();
		erc1155.mint(signer.addr, 1, 1, emptyData());
		erc1155.mint(signer.addr, 2, 1, emptyData());

		uint256[] memory ids = new uint256[](2);
		ids[0] = 1;
		ids[1] = 2;

		uint256[] memory amounts = new uint256[](2);
		amounts[0] = 1;
		amounts[1] = 1;

		expectEmitTransferBatchERC1155(signer.addr, signer.addr, address(wallet), ids, amounts);
		erc1155.safeBatchTransferFrom(signer.addr, address(wallet), ids, amounts, emptyData());
	}
}
