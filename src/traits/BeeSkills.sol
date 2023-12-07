// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BeeSkills is Ownable, ReentrancyGuard {

    enum Environments {
        fire,
        ice,
        sands,
        forest,
        water
    }

    struct BeeTraits {
        bool initializedTraits;
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

    mapping(uint256 tokenId => BeeTraits) public _tokenIdToBeeTraits;


    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function initializeBeeTraits(uint256 tokenId, bool _isQueen, Environments _environment)
        external
        returns (bool) {}
        // require(!tokenIdToBeeTraits[tokenId].initializedTraits, "Traits already initialized");
        // require(onlyOwner)

        // tokenIdToBeeTraits[tokenId] = BeeTraits({
        //     initializedTraits = true;
        //     isBeeStaked = false;
        //     isQueen = _isQueen;
        //     attack = 0;
        //     defense = 0;
        //     cooldownEndTime = 0;
        //     timeLastUpgraded = 0;
        //     foraging = 0;
        //     environment = _environment;
        // });

        // return true;

    function getBeeTraitsFromTokenId(uint256 tokenId) external {}
    // return beeTraits struct

    function upgradeAttack(uint256 tokenId, address honeyTokenAddress, address nftAddress) external {}
    // Check initializedSkills is true

    function upgradeDefense(uint256 tokenId, address honeyTokenAddress, address nftAddress) external {}
    // Check initializedSkills is true

    function upgradeForaging(uint256 tokenId, address honeyTokenAddress, address nftAddress) external {}
    // Check initializedSkills is true

    function cooldownStatus(uint256 tokenId) external {}

    function getIsQueen(uint256 tokenId) external view returns (bool) {
        return _tokenIdToBeeTraits[tokenId].isQueen;
    }
}
