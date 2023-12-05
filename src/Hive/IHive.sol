// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {TraitsState} from "../traits/TraitsState.sol";


interface IHive {

    struct HiveTraits {
        uint256 hiveId;
        uint256 numberOfQueensStaked;
        uint256 numberOfDronesStaked;
        TraitsState.Environments environment;
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
    // Transfer NFT to the Hive contract and marked as staked
    // Update tokenIdToHiveId mapping to map token to hive
    // Update allOfUsersStakedBees mapping to reflect all the bees the user has staked

    function UnstakeBee(uint256 tokenId) external returns (bool);
    // When unstaking bee, need to update number of Queen bees staked in the Hive struct
    // Calculate rewards

    function viewAmountOfClaimableTokens(address user) external view returns (uint256);

    function calculateClaimableTokens() external returns (uint256);

    function addHive() external returns (bool);

    function deleteHive() external returns (bool);
}