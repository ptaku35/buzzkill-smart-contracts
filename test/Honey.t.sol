// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "ds-test/test.sol";
import "../src/Honey/Honey.sol";

contract HoneyTest is DSTest {
    Honey honey;
    address deployer;
    address user1 = address(0x123);

    function setUp() public {
        deployer = address(this); // In Foundry, `address(this)` is the deployer
        honey = new Honey();
        honey.setControllers(deployer, true); // Assuming deployer is the owner
    }

    function test_MintTo() public {
        uint256 amount = 1e18; // 1 HONEY
        honey.mintTo(user1, amount);
        assertEq(honey.balanceOf(user1), amount);
        assertEq(honey.totalSupply(), amount);
    }

    function testFail_MintToExceedMaxSupply() public {
        uint256 amount = honey.MAX_SUPPLY() + 1;
          honey.mintTo(user1, amount); // Should fail
    }

    function test_Burn() public {
        uint256 mintAmount = 1e18;
        uint256 burnAmount = 1e17; // 0.1 HONEY
        honey.mintTo(user1, mintAmount);
        honey.burn(user1, burnAmount);
        assertEq(honey.balanceOf(user1), mintAmount - burnAmount);
        assertEq(honey.totalSupply(), mintAmount - burnAmount);
    }

    function testSetControllers() public {
        honey.setControllers(user1, true);
        // Insert assertion to check if user1 is a controller
        // This might require a function in your contract to check controller status
    }

    function testEstimateFee() public {
        uint256 value = 1e18;
        uint256 estimatedFee = honey.estimateFee(value); // This assumes estimateFee is a public function
        uint256 expectedFee = value + honey.minFee(); // Adjust accordingly
        assertEq(estimatedFee, expectedFee);
    }

    function testApproveAndAllowance() public {
        uint256 allowanceAmount = 1e18; // 1 HONEY
        honey.approve(user1, allowanceAmount);
        assertEq(honey.allowance(address(this), user1), allowanceAmount);
    }

    function testTransfer() public {
        uint256 transferAmount = 1e18; // 1 HONEY
        honey.mintTo(address(this), transferAmount);
        honey.transfer(user1, transferAmount);
        assertEq(honey.balanceOf(user1), transferAmount);
        assertEq(honey.balanceOf(address(this)), 0);
    }

    function testFailTransferNotEnoughBalance() public {
        uint256 transferAmount = 1e18; // 1 HONEY
        // This should fail since the deployer doesn't have enough balance
        honey.transfer(user1, transferAmount);
    }

    function testTransferFrom() public {
        uint256 mintAmount = 1e18; // 1 HONEY
        uint256 transferAmount = 5e17; // 0.5 HONEY
        honey.mintTo(address(this), mintAmount);
        honey.approve(user1, transferAmount);
        honey.transferFrom(address(this), user1, transferAmount);
        assertEq(honey.balanceOf(user1), transferAmount);
        assertEq(honey.balanceOf(address(this)), mintAmount - transferAmount);
    }

    function testFailTransferFromWithoutApproval() public {
        uint256 mintAmount = 1e18; // 1 HONEY
        uint256 transferAmount = 5e17; // 0.5 HONEY
        honey.mintTo(address(this), mintAmount);
        // This should fail since user1 is not approved to transfer
        honey.transferFrom(address(this), user1, transferAmount);
    }

    function testFailTransferFromExceedingAllowance() public {
        uint256 mintAmount = 1e18; // 1 HONEY
        uint256 approvedAmount = 5e17; // 0.5 HONEY
        uint256 transferAmount = 6e17; // 0.6 HONEY
        honey.mintTo(address(this), mintAmount);
        honey.approve(user1, approvedAmount);
        // This should fail since the transfer amount exceeds the approved amount
        honey.transferFrom(address(this), user1, transferAmount);
    }

}

