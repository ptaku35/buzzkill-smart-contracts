// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "lib/forge-std/src/Test.sol";
import {BuzzkillNFT} from "../src/NFT/BuzzkillNFT.sol";

contract BuzzkillTest is Test {
    BuzzkillNFT private buzzkill;

    address USER = makeAddr("user");

    function setUp() public {
        buzzkill = new BuzzkillNFT(0.0073 ether);
    }

//! Check Solmate repo for more tests.  Check Patrick repo too: https://github.com/Cyfrin/foundry-nft-f23/blob/main/test/BasicNftTest.t.sol

//! Can also write a few tests then put the format in ChatGPT and ask it to write more tests. 
//! Check this repo for a ChatGPT prompt example: https://github.com/Cyfrin/foundry-erc20-f23/blob/main/chatGPT_prompt.txt

    function test_NameIsCorrect() public view {
        string memory expectedName = "Buzzkill";
        string memory actualName = buzzkill.name();
        assert(
            keccak256(abi.encodePacked(expectedName)) ==
                keccak256(abi.encodePacked(actualName))
        );
    }

    // function test_RevertMintWithoutValue() public {
    //     vm.expectRevert(MintPriceNotPaid.selector);
    //     buzzkill.mintTo(address(USER));
    // }

    function test_MintPricePaid() public {
        buzzkill.mintTo{value: 0.0073 ether}(USER);
    }
}
