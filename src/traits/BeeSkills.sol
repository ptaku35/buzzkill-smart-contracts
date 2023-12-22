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
    uint256 public constant COOLDOWN_DURATION = 1 days;

    /// @notice Cost to raid a hive in Honey
    uint256 public constant RAIDING_COST = 10 ether;

    // TODO: Change all of these to contracts to interfaces
    /// @notice Hive contract address
    HiveVaultV1 hiveVault;

    /// @notice Staking token contract address
    BuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    Honey public rewardToken;

    mapping(uint256 tokenId => uint256 lastRaidTime) private _tokenIdToLastRaidTime;

    mapping(uint256 tokenId => BeeTraits) public _tokenIdToBeeTraits;

    enum Environments {
        fire,
        ice,
        sands,
        forest,
        water
    }

    // TODO: Add level
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
        hiveVault = HiveVaultV1(hiveVault_);
        stakingToken = BuzzkillNFT(buzzKillNFT);
        rewardToken = Honey(honey);
        // _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Modifiers                                                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyIfTraitsInitialized(uint256 tokenId) {
        require(_tokenIdToBeeTraits[tokenId].isTraitsInitialized, "Traits not initialized");
        _;
    }

    // TODO: Find another way to get token owner if this is the only usage of stakingToken contract
    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == stakingToken.ownerOf(tokenId), "Only token owner is authorized for this action");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    function upgradeAttack(uint256 tokenId, uint256 addAttack)
        external
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        // TODO: Verify energy or some mechanic to consume for adding attack
        _tokenIdToBeeTraits[tokenId].attack += addAttack;
    }

    function upgradeDefense(uint256 tokenId, uint256 addDefense)
        external
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        // TODO: Verify energy or some mechanic to consume for adding defense
        _tokenIdToBeeTraits[tokenId].defense += addDefense;
    }

    function upgradeForaging(uint256 tokenId, uint256 addForaging)
        external
        onlyIfTraitsInitialized(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        // TODO: Verify energy or some mechanic to consume for adding forage
        _tokenIdToBeeTraits[tokenId].foraging += addForaging;
    }

    // TODO:
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

        //! TODO: Need to verify this contract has authority to make transfer, will need proper allowance implementation
        // Transfer raiding cost from user
        rewardToken.transferFrom(msg.sender, owner(), RAIDING_COST);

        // TODO: Update BeeTraits such as cooldown time or energy

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

    // TODO:
    function _calculateHiveDefense(uint256 hiveId) private view returns (uint256) {
        HiveVaultV1.HiveTraits memory hiveTraits = hiveVault.getHiveTraits(hiveId);
        uint256 queens = hiveTraits.numberOfQueensStaked;
        uint256 workers = hiveTraits.numberOfWorkersStaked;
    }

    // TODO:
    function _calculateIsRaidSuccessful(uint256 attack, uint256 defense) private view returns (bool) {}
    // RN needs to be less than the attack - defense to be successful

    // TODO:
    function _calculateRaidReward() private view returns (uint256) {}

    // TODO:
    function _penalizeHive() private {}

    function _generateRandomNumber() private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
        return randomNumber % 100;
    }

    /* -------------------------------------------------------------------------- */
    /*  View Functions                                                            */
    /* -------------------------------------------------------------------------- */

    function getIsQueen(uint256 tokenId) external view returns (bool) {
        return _tokenIdToBeeTraits[tokenId].isQueen;
    }

    function getBeeTraitsFromTokenId(uint256 tokenId) external view returns (BeeTraits memory) {
        return _tokenIdToBeeTraits[tokenId];
    }

    // TODO:
    function cooldownStatus(uint256 tokenId) external {}

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

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
