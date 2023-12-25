// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console, StdStorage, stdStorage} from "forge-std/Test.sol";
import {BeeSkills} from "../src/CharacterTraits/BeeSkills.sol";

/// @notice Contract is still too into beta phase for thorough testing
contract BeeSkillsTest is Test {
    BeeSkills beeSkills;
    address deployer;
    address user1 = address(0x123);

    function setUp() public {
        deployer = address(this);
        // beeSkills = new BeeSkills();
    }
}




