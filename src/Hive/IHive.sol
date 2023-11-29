// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHive {

    ////////////////////////
    /// STATE VARIABLES 
    ////////////////////////

    // uint256 maxNumberOfBeesThatCanBeStakedPerHive
    // uint256 maxNumberOfQueenBeesThatCanBeStakedPerHive

    // mapping(uint256 tokenId => uint256 hiveId) tokenIdToHiveId
    // mapping(address user => uin256[] stakedBees) allOfUsersStakedBees

    enum Environments {
        volcano,
        ice,
        desert,
        grass,
        river
    }

    // Need to add some logic for corresponding Hive environment and bee environment
    struct HiveTraits {
        uint256 hiveId;
        uint256 numberOfQueensStaked;
        uint256 numberOfDronesStaked;
        Environments environment;
    }

    ////////////////////////
    /// EVENTS           
    ////////////////////////    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);


    ////////////////////////
    /// FUNCTIONS        
    ////////////////////////

    function stakeBee(uint256 tokenId, uint256 hiveId) external;
    // verify ownership of NFT before staking
    // Check alreadyStaked bool expression to be false
    // Transfer NFT to the Hive contract or marked as staked
    // Update tokenIdToHiveId mapping to map token to hive
    // Update allOfUsersStakedBees mapping to reflect all the bees the user has staked

    function UnstakeBee(uint256 tokenId) external;
    // When unstaking bee, need to update number of Queen bees staked in the Hive struct
    // Calculate rewards
}
