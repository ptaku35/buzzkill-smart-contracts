// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IBeeSkills {

    enum Environments {
        volcano,
        ice,
        desert,
        grass,
        river
    }

    struct beeSkills {
        bool initializedSkills;
        bool alreadyStaked;
        bool isQueen;
        uint256 attack;
        uint256 defense;
        uint256 cooldownEndTime;
        uint256 timeLastUpgraded;
        uint256 foraging;
        Environments environment;
    }

    //mapping(uint246 tokenId => beeSkills) tokenIdToBeeSkills;

    event BeeSkillUpgraded(uint256 tokeId);
    event CoolDownStarted();

    // modifier onlyTokenOwner;

    function getBeeSkillsFromTokenId(uint256 tokenId) external;
        // return beeSkills struct

    function upgradeAttack(uint256 tokenId, address honeyTokenAddress, address nftAddress) external;

    function upgradeDefense(uint256 tokenId, address honeyTokenAddress, address nftAddress) external;

    function upgradeForaging(uint256 tokenId, address honeyTokenAddress, address nftAddress) external;

    function cooldownStatus(uint256 tokenId) external;
}
