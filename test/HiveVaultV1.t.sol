// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console, StdStorage, stdStorage} from "forge-std/Test.sol";
import {HiveVaultV1} from "../src/Hive/HiveVaultV1.sol";
import {BuzzkillNFT} from "../src/NFT/BuzzkillNFT.sol";
import {Honey} from "../src/Honey/Honey.sol";
import {IERC721Receiver} from "@vrc725/contracts/interfaces/IERC721Receiver.sol";


contract HiveVaultV1Test is Test {
    BuzzkillNFT nft;
    Honey rewardToken;
    HiveVaultV1 hive;

    address deployer;
    address user1 = address(0x123);

    address beeSkillsAddress = 0x36bc480435F4C55f59CF49d6D4D9B48ca63bDF36;

    uint256 hiveId = 1;
    uint256 tokenId = 1;


    function setUp() public {
        deployer = address(this); // In Foundry, `address(this)` is the deployer
        nft = new BuzzkillNFT(1 ether);
        rewardToken = new Honey();
        hive = new HiveVaultV1(
            deployer,
            address(nft),
            address(rewardToken),
            beeSkillsAddress,
            10e18,
            3,
            25,
            1 days,
            1 days
        );

        // Add a hive to kick off the hiveId
        hive.pause();
        hive.addHive(HiveVaultV1.Environments.fire, 50);
        hive.unpause();

        // Simulate minting a bee
        nft.mintTo(user1);
        vm.prank(user1);
        nft.approve(address(hive), tokenId);

    }

    function test_StakeBeeSuccess() public {
        vm.startPrank(user1);
        bool success = hive.stakeBee(tokenId, hiveId);
        vm.stopPrank();
        assertTrue(success);
    }

    function test_StakeBeeFailureNotOwner() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert("Error: Only token owner can stake");
        hive.stakeBee(tokenId, hiveId);
    }

    function test_StakeBeeFailureInvalidHiveId() public {
        vm.prank(user1);
        vm.expectRevert("Error: Invalid hive ID");
        hive.stakeBee(tokenId, 999); // Assuming 999 is an invalid hive ID
    }

    function test_UnstakeBeeSuccess() public {
        vm.prank(user1);
        hive.stakeBee(tokenId, 1);
        vm.warp(block.timestamp + 1 days); // Advance time to simulate lock-up period expiry
        vm.prank(user1);
        bool success = hive.unstakeBee(tokenId);
        assertTrue(success);
    }

    function test_UnstakeBeeFailure_NotOwner() public {
        vm.expectRevert("Error: Not token owner or NFT not staked");
        hive.unstakeBee(tokenId);
    }

    function test_UnstakeBeeFailureLockupNotExpired() public {
        vm.prank(user1);
        vm.expectRevert("Lock-up period not expired");
        hive.unstakeBee(tokenId);
    }

    function test_ClaimSuccess() public {
        vm.startPrank(user1);
        hive.stakeBee(tokenId, 1);
        vm.warp(block.timestamp + 1 days); // Advance time to simulate staking period
        hive.claim();
        vm.stopPrank();
        uint256 userBalance = rewardToken.balanceOf(user1);
        assertTrue(userBalance > 0); // Check that the user has received some rewards
    }

    function test_AddHiveSuccess() public {
        hive.pause(); // Ensure the contract is paused for testing addHive
        HiveVaultV1.Environments environment = HiveVaultV1.Environments.fire;
        uint256 hiveDefense = 10;
        vm.prank(deployer);
        bool success = hive.addHive(environment, hiveDefense);
        assertTrue(success);
    }

    function test_AddHiveOnlyOwner() public {
        address nonOwner = address(0x456);
        HiveVaultV1.Environments environment = HiveVaultV1.Environments.fire;
        uint256 hiveDefense = 10;
        vm.prank(nonOwner);
        vm.expectRevert(); 
        hive.addHive(environment, hiveDefense);
    }

    function testFail_AddHiveWhenUnpaused() public {
        hive.unpause(); 
        HiveVaultV1.Environments environment = HiveVaultV1.Environments.fire;
        uint256 hiveDefense = 10;
        vm.prank(deployer);
        hive.addHive(environment, hiveDefense);
    }

    function test_DeleteHiveSuccess() public {
        hive.pause();
        vm.prank(deployer);
        bool success = hive.deleteHive(hiveId);
        assertTrue(success);
    }

    function test_DeleteHiveOnlyOwner() public {
        address nonOwner = address(0x456);
        vm.prank(nonOwner);
        vm.expectRevert(); 
        hive.deleteHive(hiveId);
    }

    function testFail_DeleteHiveWhenUnpaused() public {
        hive.unpause(); 
        vm.prank(deployer);
        hive.deleteHive(hiveId);
    }

    function test_OnERC721Received() public {
        bytes4 expectedSelector = IERC721Receiver.onERC721Received.selector;
        bytes4 returnedSelector = hive.onERC721Received(address(0), address(0), 0, "");
        assertEq(returnedSelector, expectedSelector, "onERC721Received does not return the correct selector");
    }

    function test_DirectERC721Transfer() public {
        nft.mintTo(address(hive));
        // Verify that the token is indeed transferred and that HiveVaultV1 is now the owner
        address ownerOfToken = nft.ownerOf(2);
        assertEq(ownerOfToken, address(hive), "Token was not transferred correctly");
    }
}