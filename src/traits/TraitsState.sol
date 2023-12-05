// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title TraitsState
 * This contract is for stating all Traits that will
 * be used across other contracts.
 *
 * Environments is a trait in both HiveTraits in the Hive
 * contract and BeeTraits in the BeeTraits contact.
 *
 * BeeTraits is used in the Hive and BeeTraits contracts.
 * Hive has to call BeeTraits when NFT is staked and unstaked.
 */

abstract contract TraitsState {

    enum Environments {
        fire,
        ice,
        desert,
        forest,
        water
    }
    
    struct HiveTraits {
        uint256 hiveId;
        uint256 numberOfQueensStaked;
        uint256 numberOfWorkersStaked;
        uint256 hiveDefense; // b/w 0-50
        Environments environment;
    }

    struct BeeTraits {
        bool initializedTraits;
        bool isBeeStaked;
        bool isQueen;
        uint256 currentEnergy;
        uint256 maxEnergy;
        uint256 resetEnergy; // Using block.number or block.timestamp to track resetEnergy; use coolDownEndTime to track
        uint256 cooldownEndTime;
        uint256 attack;
        uint256 defense;
        uint256 timeLastUpgraded;
        uint256 foraging;
        Environments environment;
    }

    mapping(uint256 tokenId => BeeTraits) tokenIdToBeeTraits;
}
