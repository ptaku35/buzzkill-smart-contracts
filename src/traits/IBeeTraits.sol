// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {TraitsState} from "../traits/TraitsState.sol";

interface IBeeTraits {
    ////////////////////////
    /// EVENTS
    ////////////////////////

    event BeeTraitUpgraded(uint256 tokeId);
    event CoolDownStarted();

    ////////////////////////
    /// MODIFIERS
    ////////////////////////

    // modifier onlyTokenOwner;

    ////////////////////////
    /// FUNCTIONS
    ////////////////////////
    function initializeBeeTraits(uint256 tokenId, bool _isQueen, TraitsState.Environments _environment)
        external
        returns (bool);
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

    function getBeeTraitsFromTokenId(uint256 tokenId) external;
    // return beeTraits struct

    function upgradeAttack(uint256 tokenId, address honeyTokenAddress, address nftAddress) external;
    // Check initializedSkills is true

    function upgradeDefense(uint256 tokenId, address honeyTokenAddress, address nftAddress) external;
    // Check initializedSkills is true

    function upgradeForaging(uint256 tokenId, address honeyTokenAddress, address nftAddress) external;
    // Check initializedSkills is true

    function cooldownStatus(uint256 tokenId) external;
}
