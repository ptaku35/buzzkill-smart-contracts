// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IBuzzkillNFT} from "../interfaces/IBuzzkillNFT.sol";
import {IHiveVaultV1} from "../interfaces/IHiveVaultV1.sol";
import {IHoney} from "../interfaces/IHoney.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @notice This contract is a big work-in-progress.  It will provide the main functionality
 * of the game mechanics that will allow users to "raid" other hives to try and still honey
 * tokens as well as upgrade attack and defenses that are used for a probabilistic calculation
 * to determine a succesful raid.
 */


contract BeeSkills is Ownable, Pausable, ReentrancyGuard {

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Cooldown period for NFT to raid a hive
    uint256 public constant COOLDOWN_DURATION = 1 days;

    /// @notice Cost to raid a hive in Honey
    uint256 public constant RAIDING_COST = 10 ether;

    ///@notice Value of how much more queens are worth in defense than workers
    uint8 private QUEEN_TO_WORKER_RATIO = 5;

    /// @notice Hive contract address
    IHiveVaultV1 hiveVault;

    /// @notice Staking token contract address
    IBuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    IHoney public rewardToken;

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
        uint256 cooldownEndTime;
        uint256 attack;
        uint256 defense;
        uint256 timeLastUpgraded;
        uint256 foraging;
        uint8 level;
        Environments environment;
    }

    /* -------------------------------------------------------------------------- */
    /*  Events                                                                    */
    /* -------------------------------------------------------------------------- */

    event RaidSuccessful(address indexed raider, uint256 tokenId, uint256 hiveId, uint256 honeyMinted);
    event RaidFailed(address indexed raider, uint256 tokenId, uint256 hiveId);

    /* -------------------------------------------------------------------------- */
    /*  Constructor                                                               */
    /* -------------------------------------------------------------------------- */

    constructor(address payable owner_, address hiveVault_, address buzzKillNFT, address honey)
        Ownable(owner_)
    {
        hiveVault = IHiveVaultV1(hiveVault_);
        stakingToken = IBuzzkillNFT(buzzKillNFT);
        rewardToken = IHoney(honey);
        // _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Modifiers                                                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyIfTraitsInitialized(uint256 tokenId) {
        require(_tokenIdToBeeTraits[tokenId].isTraitsInitialized, "Traits not initialized");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == stakingToken.ownerOf(tokenId), "Only token owner is authorized for this action");
        _;
    } 

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Upgrades the attack trait of a given token
    /// @param tokenId The token ID of the bee to upgrade
    /// @param addAttack The amount of attack to add to the token
    function upgradeAttack(uint256 tokenId, uint256 addAttack)
        external
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        // TODO: Verify energy or some mechanic to consume for adding attack
        _tokenIdToBeeTraits[tokenId].attack += addAttack;
    }

    /// @notice Upgrades the defense trait of a given token
    /// @param tokenId The token ID of the bee to upgrade
    /// @param addDefense The amount of defense to add to the token
    function upgradeDefense(uint256 tokenId, uint256 addDefense)
        external
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        // TODO: Verify energy or some mechanic to consume for adding defense
        _tokenIdToBeeTraits[tokenId].defense += addDefense;
    }

    /// @notice Upgrades the foraging trait of a given token
    /// @param tokenId The token ID of the bee to upgrade
    /// @param addForaging The amount of foraging ability to add to the token
    function upgradeForaging(uint256 tokenId, uint256 addForaging)
        external
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        // TODO: Verify energy or some mechanic to consume for adding forage
        _tokenIdToBeeTraits[tokenId].foraging += addForaging;
    }

    // TODO: Finish raid mechanics
    /// @notice Conducts a raid on a specified hive using a bee NFT
    /// @param tokenId The token ID of the raiding bee
    /// @param hiveId The ID of the hive to be raided
    /// @return A boolean indicating if the raid was successful
    function raidAHive(uint256 tokenId, uint256 hiveId)
        external
        payable
        nonReentrant
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
        returns (bool)
    {
        // Require user to not raid own hive
        require(hiveVault._tokenIdToHiveId(tokenId) != hiveId, "Cannot raid your own hive");
        // Require NFT must be staked
        require(hiveVault._tokenIdToHiveId(tokenId) != 0, "Token must be staked to raid");
        // Require cooldown period to have passed or enough energy; not sure which yet
        // Require owner to have honey to raid
        require(rewardToken.balanceOf(msg.sender) >= RAIDING_COST);

        // Transfer raiding cost from user
        rewardToken.transferFrom(msg.sender, owner(), RAIDING_COST);

        // Get traits
        uint256 beeAttack = _tokenIdToBeeTraits[tokenId].attack;
        uint256 hiveDefense = _calculateHiveDefense(hiveId);

        // Raid hive
        bool isRaidSuccesful = _calculateIsRaidSuccessful(beeAttack, hiveDefense);

        if (isRaidSuccesful) {
            // calculate winnings and mint/transfer
            uint256 loot = _calculateRaidReward();
            rewardToken.mintTo(msg.sender, loot);

            // Penalize raided hive
            _penalizeHive();

            emit RaidSuccessful(msg.sender, tokenId, hiveId, loot);
            return true;
        } else {
            emit RaidFailed(msg.sender, tokenId, hiveId);
            return true;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*  Private/Internal Functions                                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculates the defense of a hive based on its traits
    /// @param hiveId The ID of the hive whose defense is being calculated
    /// @return The calculated defense value of the hive
    function _calculateHiveDefense(uint256 hiveId) private view returns (uint256) {
        IHiveVaultV1.HiveTraits memory hiveTraits = hiveVault.getHiveTraits(hiveId);
        uint256 queens = hiveTraits.numberOfQueensStaked;
        uint256 workers = hiveTraits.numberOfWorkersStaked;
        return queens * QUEEN_TO_WORKER_RATIO + workers;
    }

    // TODO
    /// @notice This will calculate the probability of a succesful raid 
    function _calculateIsRaidSuccessful(uint256 attack, uint256 defense) private view returns (bool) {}
    // RN needs to be less than the attack - defense to be successful

    // TODO
    /// @notice This will calculate how much will be stolen from the hive if raid is succesful
    function _calculateRaidReward() private view returns (uint256) {}

    // TODO
    /// @notice This will penalize the hive by transferring tokens out based on _calculateRaidReward
    function _penalizeHive() private {}

    function _generateRandomNumber() private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
        return randomNumber % 100;
    }

    /* -------------------------------------------------------------------------- */
    /*  View Functions                                                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Checks if a given token represents a queen bee
    /// @param tokenId The token ID to check
    /// @return A boolean indicating if the token is a queen bee
    function getIsQueen(uint256 tokenId) external view returns (bool) {
        return _tokenIdToBeeTraits[tokenId].isQueen;
    }

    /// @notice Get bee traits for a give token Id
    function getBeeTraitsFromTokenId(uint256 tokenId) external view returns (BeeTraits memory) {
        return _tokenIdToBeeTraits[tokenId];
    }

    // TODO
    /// @notice This will verify cooldown status so users cannot spam attacks
    function cooldownStatus(uint256 tokenId) external {}

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Initializes the traits of a bee token
    /// @dev This needs to be done for each token
    /// @param tokenId The token ID of the bee to initialize
    /// @param _isQueen Indicates if the bee is a queen
    /// @param _environment The environment of the bee
    /// @return A boolean indicating if the initialization was successful
    function initializeBeeTraits(uint256 tokenId, bool _isQueen, Environments _environment)
        external
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        require(!_tokenIdToBeeTraits[tokenId].isTraitsInitialized, "Traits already initialized");

        _tokenIdToBeeTraits[tokenId] = BeeTraits({
            isTraitsInitialized: true,
            isQueen: _isQueen,
            currentEnergy: 100,
            maxEnergy: 100,
            cooldownEndTime: COOLDOWN_DURATION,
            attack: 50,
            defense: 50,
            timeLastUpgraded: 0,
            foraging: 0,
            level: 1,
            environment: _environment
        });

        return true;
    }

    /// @notice Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}
