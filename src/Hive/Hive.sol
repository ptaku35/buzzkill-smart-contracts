// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * TODO list
 * 2. Need a function to check for remaining Queens in the hive and update APR accordingly - function unstakeBeeAndClaimRewards
 * 6. Refactor any functions and add additional functions to perform logic where it can be done.
 * 8. Incorporate unused variables i.e. maxNumberOfWorkersThatCanBeStakedPerHive
 * 9. Consider raiding mechanics in Hive contract
 */

contract Hive {

    function raidAHive(uint256 tokenId, uint256 hiveId) external returns (bool) {
        // require ownership tokenId
        // require("Can't raid your own hive")
        // require("Not enough energy") or "Already raided today"

        // Add a cost to raid
        // Check that tokenId owner has honey to pay for raid
        // honey.transferFrom(msg.sender, toSomeAddress, 10 tokens) // Need to make sure this contract is authorized to transfer from user's account
        // Could burn some, could send some to hive, could send some to a general account (ecosystem), maybe revenue

        // Attack Mechanics
        // Need BeeTraits - Attack
        // Need Hive defense - call HiveTraits
        // random number generator
        // RN needs to be less than the attack - defense to be successful
        // update any BeeTraits such as energy, cooldown time, etc

        // If raid fails, do:
        // do nothing, return fail
        // If raid succeeds, do:
        // Take $honey from the raided Hive
        // Amount will be some percent of the total Hive pool

        // Future Iterations:
        // VRF
        // Allocate some honey to wallet and HivePool
        // Luck powerup - pay for powerup, increases raid success probability
        // Account for Hive or bee environment
    }
}
