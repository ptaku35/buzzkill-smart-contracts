// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IHive {

    ////////////////////////
    /// STATE VARIABLES 
    ////////////////////////

    // uint256 maxNumberOfBeesThatCanBeStakedPerHive
    // uint256 maxNumberOfQueenBeesThatCanBeStakedPerHive

    // mapping(uint256 tokenId => uint256 hiveId) tokenIdToHiveId
    // mapping(address user => uin256[] stakedBees) ListOfUsersStakedBees
    // mapping(uint256 tokenId) vault

    enum Environments {
        volcano,
        ice,
        desert,
        grass,
        river
    }


    struct HiveTraits {
        uint256 hiveId;
        uint256 numberOfQueensStaked;
        uint256 numberOfDronesStaked;
        Environments environment;
    }

    ////////////////////////
    /// EVENTS           
    ////////////////////////    
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);


    ////////////////////////
    /// FUNCTIONS        
    ////////////////////////

    function stakeBee(uint256 tokenId, uint256 hiveId) external returns (bool);
    // verify ownership of NFT before staking
    // Check alreadyStaked bool expression to be false
    // Transfer NFT to the Hive contract or marked as staked
    // Update tokenIdToHiveId mapping to map token to hive
    // Update allOfUsersStakedBees mapping to reflect all the bees the user has staked

    function UnstakeBee(uint256 tokenId) external returns (bool);
    // When unstaking bee, need to update number of Queen bees staked in the Hive struct
    // Calculate rewards

    function addHive() external returns (bool);

    function deleteHive() external returns (bool);
}
