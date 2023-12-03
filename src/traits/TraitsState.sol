// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract TraitsState {
    enum Environments {
        fire,
        ice,
        desert,
        forest,
        water
    }

    struct BeeTraits {
        bool initializedTraits;
        bool isBeeStaked;
        bool isQueen;
        uint256 tokenId;
        uint256 attack;
        uint256 defense;
        uint256 cooldownEndTime;
        uint256 timeLastUpgraded;
        uint256 foraging;
        Environments environment;
    }

    mapping(uint256 tokenId => BeeTraits) tokenIdToBeeTraits;
}
