// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {HiveVaultV1} from "../Hive/HiveVaultV1.sol";
import {Honey} from "../Honey/Honey.sol";
import {BuzzkillNFT} from "../NFT/BuzzkillNFT.sol";
import {BeeSkills} from "../traits/BeeSkills.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BeeSkills is Ownable, Pausable, ReentrancyGuard {

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Cooldown period for NFT to raid a hive
    uint256 constant public COOLDOWN_DURATION = 1 days;

    /// @notice Cost to raid a hive in Honey
    uint256 constant public RAIDING_COST = 10 ether;

    /// @notice owner of this contract
    address payable owner;

    /// @notice Hive contract address
    HiveVaultV1 hiveVault;

    /// @notice Staking token contract address
    BuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    Honey public rewardToken;

    /// @notice Bee traits contract address
    BeeSkills public beeSkills;

    mapping(uint256 tokenId => uint256 lastRaidTime) private _tokenIdToLastRaidTime;

    mapping(uint256 tokenId => BeeTraits) public _tokenIdToBeeTraits;

    enum Environments {
        fire,
        ice,
        sands,
        forest,
        water
    }

    struct BeeTraits {
        bool isTraitsInitialized;
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

    /* -------------------------------------------------------------------------- */
    /*  Events                                                                    */
    /* -------------------------------------------------------------------------- */

    event RaidSuccessful(address indexed raider, uint256 hiveId, uint256 honeyMinted);
    event RaidFailed(address indexed raider, uint256 hiveId);

    /* -------------------------------------------------------------------------- */
    /*  Constructor                                                               */
    /* -------------------------------------------------------------------------- */

    constructor(
        address payable owner_, 
        address hiveVault_,
        address buzzKillNFT, 
        address honey, 
        address beeSkills_) 
        Ownable(owner_) {
            owner = owner_;
            hiveVault = HiveVaultV1(hiveVault_);
            stakingToken = BuzzkillNFT(buzzKillNFT);
            rewardToken = Honey(honey);
            beeSkills = BeeSkills(beeSkills_);
            _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Modifiers                                                                 */
    /* -------------------------------------------------------------------------- */

        // Modifer to verify initialized skills

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

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

    function raidAHive(uint256 tokenId, uint256 hiveId) payable external nonReentrant returns (bool) {
        // Require ownership of raiding NFT
        require(msg.sender == stakingToken.ownerOf(tokenId), "Only owner of token can raid");
        // Require user to not raid own hive
        require(hiveVault._tokenIdToHiveId(tokenId) != hiveId, "Cannot raid your own hive");
        // Require NFT must be staked
        require(hiveVault._tokenIdToHiveId(tokenId) != 0, "Token must be staked to raid");
        // Require cooldown period to have passed or enough energy; not sure which yet

        // Require owner to have honey to raid
        require(rewardToken.balanceOf(msg.sender) >= RAIDING_COST);

        // Transfer raiding cost from user
        rewardToken.transferFrom(msg.sender, owner, RAIDING_COST); //! Need to verify this contract has authority to make transfer

        // Attack Mechanics
        // Need BeeTraits - Attack
        uint256 attack = _tokenIdToBeeTraits[tokenId].attack;
        // Need Hive defense - call HiveTraits
        // uint256 defense = hiveVault._hiveIdToHiveTraits(hiveId).hiveDefense;
        // random number generator
        // RN needs to be less than the attack - defense to be successful
        // update any BeeTraits such as energy, cooldown time, etc

        // If raid fails, do:
        // do nothing, return fail
        // If raid succeeds, do:
        // Take $honey from the raided Hive
        // Amount will be some percent of the total Hive pool

        // TODO: Consider a transaction fee for raiding

        // Future Iterations:
        // VRF
        // Allocate some honey to wallet and HivePool
        // Luck powerup - pay for powerup, increases raid success probability
        // Account for Hive or bee environment
    }

    /* -------------------------------------------------------------------------- */
    /*  Private/Internal Functions                                                */
    /* -------------------------------------------------------------------------- */

    function generateRandomNumber() private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
        return randomNumber % 100;
    }



    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}
