// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console, StdStorage, stdStorage} from "forge-std/Test.sol";
import {BuzzkillNFT} from "../src/NFT/BuzzkillNFT.sol";

//! Check Solmate repo for more tests.  Check Patrick repo too: https://github.com/Cyfrin/foundry-nft-f23/blob/main/test/BasicNftTest.t.sol
//! Can also write a few tests then put the format in ChatGPT and ask it to write more tests.
//! Check this repo for a ChatGPT prompt example: https://github.com/Cyfrin/foundry-erc20-f23/blob/main/chatGPT_prompt.txt

contract BuzzkillTest is Test {
    using stdStorage for StdStorage;

    string constant NFT_NAME = "Buzzkill";
    string constant NFT_SYMBOL = "BZK";
    string constant BASE_URI = "ipfs://<SOME HASH HERE>/";
    uint256 public constant TOTAL_SUPPLY = 10_000;
    BuzzkillNFT private nft;

    address USER = makeAddr("user");

    function setUp() public {
        nft = new BuzzkillNFT(1 ether);
    }

    /* -------------------------------------------------------------------------- */
    /*  Test Mint                                                                 */
    /* -------------------------------------------------------------------------- */

    // Test mint price has been paid
    function test_MintPricePaid() public {
        nft.mintTo{value: 1 ether}(USER);
    }

    // Test mint price hasn't been sent
    function testfail_MintPriceNotPaid() public {
        nft.mintTo(address(USER));
    }

    // Test mint price is not accepted outside of range
    function testfail_MintPriceOutOfRange() public {
        nft.mintTo{value: 10 ether}(USER);
    }

    // Test minting and balances updates correctly
    function test_CanMintAndHaveABalance() public {
        nft.mintTo{value: 1 ether}(USER);
        assert(nft.balanceOf(USER) == 1);
    }

    // Test supply is updated correctly
    function test_MintAndSuppply() public {
        nft.mintTo{value: 1 ether}(USER);
        nft.mintTo{value: 1 ether}(USER);
        assertEq(nft.totalSupply(), 2);
    }

    // Test mint to zero address
    function testFail_MintToZeroAddress() public {
        nft.mintTo{value: 1 ether}(address(0));
        vm.expectRevert("ERC721: mint to the zero address");
    }

    // Test new mint registers owner
    function test_NewMintOwnerRegistered() public {
        // Mint nft
        nft.mintTo{value: 1 ether}(USER);
        // Store address of owner
        uint256 slotOfNewOwner = stdstore.target(address(nft)).sig(nft.ownerOf.selector).with_key(1).find();
        // Retrieve address
        uint160 ownerOfTokenIdOne = uint160(uint256(vm.load(address(nft), bytes32(abi.encode(slotOfNewOwner)))));
        // Check retrieved address equals USER
        assertEq(address(ownerOfTokenIdOne), address(USER));
    }

    // Test max supply reverts when exceeded
    function testFail_MaxSupplyReached() public {
        uint256 slot = stdstore.target(address(nft)).sig("currentTokenId()").find();
        bytes32 location = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(TOTAL_SUPPLY));
        vm.store(address(nft), location, mockedCurrentTokenId);
        vm.prank(USER);
        nft.mintTo{value: 1 ether}(USER);
        vm.expectRevert("MaxSupplyExceeded()");
    }

    // Test that the balance increments correctly
    function test_BalanceIncremented() public {
        nft.mintTo{value: 1 ether}(USER);
        uint256 slotBalance = stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(USER).find();
        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mintTo{value: 1 ether}(USER);
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    /* -------------------------------------------------------------------------- */
    /*  Test Burn                                                                 */
    /* -------------------------------------------------------------------------- */

    // Test burning a token
    function test_CanBurnToken() public {
        nft.mintTo{value: 1 ether}(USER);
        nft.burn(1);
        assertEq(nft.balanceOf(USER), 0);
    }

    // Test burning a non-existent token
    function testFail_BurnNonExistentToken() public {
        nft.burn(1);
    }

    // Test burning a token not owned by owner
    function testFail_BurnTokenNotOwned() public {
        nft.mintTo{value: 1 ether}(address(this));
        vm.prank(USER);
        nft.burn(1);
    }

    /* -------------------------------------------------------------------------- */
    /*  Test Transfers                                                            */
    /* -------------------------------------------------------------------------- */

    // Test successful transfer
    function test_CanTransferToken() public {
        nft.mintTo{value: 1 ether}(USER);
        vm.prank(USER);
        nft.safeTransferFrom(USER, address(1), 1);
        assertEq(nft.balanceOf(address(1)), 1);
    }

    // Test transfer of non-existent token
    function testFail_TransferNonExistentToken() public {
        vm.prank(USER);
        nft.safeTransferFrom(USER, address(this), 1);
    }

    // Test transfer from not owner
    function testFail_TransferFromNotOwner() public {
        nft.mintTo{value: 1 ether}(address(this));
        vm.prank(USER);
        nft.safeTransferFrom(address(this), USER, 1);
    }

    /* -------------------------------------------------------------------------- */
    /*  Test Approvals                                                            */
    /* -------------------------------------------------------------------------- */

    // Test approvals

    /* -------------------------------------------------------------------------- */
    /*  Test Withdraw Payments                                                    */
    /* -------------------------------------------------------------------------- */

    // Test Withdraw from the NFT address as owner
    function test_WithdrawWorksAsOwner() public {
        // Mint and check balance
        uint256 balanceBefore = address(nft).balance;
        nft.mintTo{value: 1 ether}(USER);
        uint256 contractBalance = address(nft).balance;
        assertEq(contractBalance, nft.mintPrice());

        // Withdraw and check balance
        nft.withdrawPayments(payable(address(1)));
        uint256 balanceAfter = address(nft).balance;
        assertEq(balanceBefore, balanceAfter);
    }

    // Test Withdraw fails as not owner
    function testFail_WithdrawFailsAsNotOwner() public {
        // Mint NFT, send eth to the contract
        nft.mintTo{value: nft.mintPrice()}(USER);
        // Check that the balance of the contract is correct
        assertEq(address(nft).balance, nft.mintPrice());
        // Confirm that a non-owner cannot withdraw
        vm.startPrank(address(USER));
        nft.withdrawPayments(payable(USER));
        vm.stopPrank();
    }

    /* -------------------------------------------------------------------------- */
    /*  Test Other Logic                                                          */
    /* -------------------------------------------------------------------------- */

    function test_InitializedCorrectly() public view {
        assert(keccak256(abi.encodePacked(nft.name())) == keccak256(abi.encodePacked((NFT_NAME))));
        assert(keccak256(abi.encodePacked(nft.symbol())) == keccak256(abi.encodePacked((NFT_SYMBOL))));
    }

    function test_TokenURIIsCorrect() public {
        nft.mintTo{value: 1 ether}(USER);
        nft.mintTo{value: 1 ether}(USER);
        nft.mintTo{value: 1 ether}(USER);
        assert(keccak256(abi.encodePacked(nft.tokenURI(3))) == keccak256(abi.encodePacked(BASE_URI, "3")));
    }

    // Test mint price updates correctly
    function test_UpdatesMintPrice() public {
        uint256 currentMintPrice = nft.mintPrice();
        nft.UpdateMintPrice(2 ether);
        uint256 newMintPrice = nft.mintPrice();
        assertEq(currentMintPrice, 1 ether);
        assertEq(newMintPrice, 2 ether);
    }

    // Test revert when contract is paused
    function testFail_WithPausedContract() public {
        nft.pause();
        vm.startPrank(USER);
        nft.mintTo{value: 1 ether}(USER);
        vm.expectRevert("EnforcedPause()");
        vm.stopPrank();
    }

    // Maybe test enumerable
}
