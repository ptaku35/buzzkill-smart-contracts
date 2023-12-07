// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Honey} from "../Honey/Honey.sol";
import {BuzzkillNFT} from "../NFT/BuzzkillNFT.sol";
import {BeeSkills} from "../traits/BeeSkills.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Hive Vault
contract HiveVaultV1 is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Id assigned to a hive
    uint256 private currentHiveId;

    /// @notice Rewards emitted per day staked
    uint256 private rate;

    /// @notice Endtime of token rewards
    uint256 private endTime;

    /// @notice Limit of worker bees per hive
    uint256 private maxWorkersPerHive;

    /// @notice Limit of queen bees per hive
    uint256 private maxQueensPerHive;

    /// @notice Interval for updating rewards earned
    uint256 public rewardInterval;

    /// @notice Keep track of timestamp at the last reward interval
    uint256 private lastRewardIntervalTimestamp;

    /// @notice Time of a single epoch
    uint256 private epochDuration;

    /// @notice Staking token contract address
    BuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    Honey public rewardToken;

    /// @notice Bee traits contract address
    BeeSkills public beeSkills;

    /// @notice Set of staked token Ids by address
    mapping(address user => EnumerableSet.UintSet stakedTokenIds) internal _depositedIds;

    /// @notice Mapping of timestamps from each staked token id
    mapping(uint256 tokenId => uint256 timestamp) public _depositedBlocks;

    /// @notice Mapping from tokenId to accumulated rewards
    mapping(uint256 tokenId => uint256 accumulatedRewards) public _tokenIdToAccumulatedRewards;

    /// @notice Mapping of hive to its hive traits
    mapping(uint256 hiveId => HiveTraits hiveTraits) public _hiveIdToHiveTraits;

    /// @notice Mapping of staking token to its staked hive
    mapping(uint256 tokenId => uint256 hiveId) public _tokenIdToHiveId;

    /// @notice Mapping of hiveIds to their rate modifier
    mapping(uint256 hiveId => uint256 rateModifier) public _rateModifiers;

    /// @notice Different hive environments
    enum Environments {
        fire,
        ice,
        sands,
        forest,
        water
    }

    /// @notice Various hive straits
    struct HiveTraits {
        uint256 hiveId;
        uint256 numberOfQueensStaked;
        uint256 numberOfWorkersStaked;
        uint256 hiveDefense; // b/w 0-50
        Environments environment;
    }

    /* -------------------------------------------------------------------------- */
    /*  Events                                                                    */
    /* -------------------------------------------------------------------------- */

    event NFTStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event Claimed(address indexed nftOwner, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*  Constructor                                                               */
    /* -------------------------------------------------------------------------- */

    constructor(
        address initialOwner,
        address buzzkillNFT,
        address honey,
        address _beeSkills,
        uint256 initialRewardsRate,
        uint256 _maxQueensPerHive,
        uint256 _maxWorkersPerHive,
        uint256 _rewardInterval,
        uint256 _epochDuration
    ) Ownable(initialOwner) {
        stakingToken = BuzzkillNFT(buzzkillNFT);
        rewardToken = Honey(honey);
        beeSkills = BeeSkills(_beeSkills);
        rate = initialRewardsRate;
        maxWorkersPerHive = _maxWorkersPerHive;
        maxQueensPerHive = _maxQueensPerHive;
        rewardInterval = _rewardInterval;
        lastRewardIntervalTimestamp = block.timestamp;
        epochDuration = _epochDuration;
        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Stake the specified NFT (`tokenId`) into the hive with the given ID (`hiveId`).
    /// @param tokenId The unique identifier of the NFT to be staked.
    /// @param hiveId The ID of the hive where the NFT will be staked.
    function stakeBee(uint256 tokenId, uint256 hiveId) external whenNotPaused returns (bool) {
        require(msg.sender == stakingToken.ownerOf(tokenId), "Error: Only token owner can stake");
        require(hiveId <= currentHiveId && hiveId > 0, "Error: Invalid hive ID");
        require(currentHiveId > 0, "Error: No Hives have been created");
        // Update Hive traits
        updateBeeCountInHive(hiveId, beeSkills.getIsQueen(tokenId), true);
        // Update token to hive mapping
        _tokenIdToHiveId[tokenId] = hiveId;
        // Transfer NFT to vault
        deposit(tokenId);

        return true;
    }

    /// @notice Unstake a bee NFT and claim rewards based on the time it has been staked.
    /// @dev The caller must be the owner of the NFT and the NFT must be currently staked.
    /// @param tokenId The unique identifier of the bee NFT to be unstaked and claimed.
    function unstakeBee(uint256 tokenId) external whenNotPaused returns (bool) {
        // Get hive Id
        uint256 hiveId = _tokenIdToHiveId[tokenId];
        // Update Hive traits
        updateBeeCountInHive(hiveId, beeSkills.getIsQueen(tokenId), false);
        // Update token to hive mapping
        delete _tokenIdToHiveId[tokenId];
        // Transfer NFT back to user
        withdraw(tokenId);

        return true;
    }

    /// @notice Claim pending token rewards
    ///  TODO: Review this from changing the mapping from user=>tokenID=>timestamp
    function claim() external whenNotPaused nonReentrant {
        uint256 totalRewards;
        uint256 length = _depositedIds[msg.sender].length();
        uint256 tokenId;
        for (uint256 i = 0; i < length; i++) {
            // Calculate total rewards
            tokenId = _depositedIds[msg.sender].at(i);
            totalRewards += _earned(_depositedBlocks[tokenId], tokenId);
            // Update last checkpoint
            _depositedBlocks[tokenId] = block.timestamp;
        }
        // Mint new tokens
        rewardToken.mintTo(msg.sender, totalRewards);

        emit Claimed(msg.sender, block.timestamp);
    }

    /// @notice Calculating rewards at each reward interval
    function accumulatedTokenIdRewards(uint256 tokenId) external onlyOwner returns (uint256 rewards) {
        require(stakingToken.currentTokenId() <= tokenId, "Token ID doesn't exist");
        require(
            block.timestamp >= lastRewardIntervalTimestamp + rewardInterval,
            "Can only be called once every reward Interval"
        );

        // Need rate modifier
        uint256 hiveId = _tokenIdToHiveId[tokenId];
        uint256 rateModifier = _rateModifiers[hiveId];

        // Need staked timestamp
        uint256 startingStakedTime = _depositedBlocks[tokenId];

        // Need current timestamp
        uint256 currentTimestamp = block.timestamp;
        // Need rewardIntervalTimestamp TODO: Need to update this every interval

        // need an accumulator variable to keep track of accrued reward for each tokenId
        _tokenIdToAccumulatedRewards[tokenId] += rateModifier * (currentTimestamp - startingStakedTime);

        lastRewardIntervalTimestamp = block.timestamp;
        _depositedBlocks[tokenId] = lastRewardIntervalTimestamp;
        // accum += rewardAtEachInterval
    }

    /* -------------------------------------------------------------------------- */
    /*  Private/Internal Functions                                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Deposit tokens into the vault
    /// @param tokenId Token to be deposited
    function deposit(uint256 tokenId) private nonReentrant {
        // Add the new deposit to the mapping and check that NFT is not already staked
        bool success = _depositedIds[msg.sender].add(tokenId);
        require(success, "NFT already staked");
        // Set timestamp for tokenId
        _depositedBlocks[tokenId] = block.timestamp;
        // Transfer the deposited token to this contract
        stakingToken.safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTStaked(msg.sender, tokenId, block.timestamp);
    }

    /// @notice Withdraw tokens and claim their pending rewards
    /// @param tokenId Staked token Id
    function withdraw(uint256 tokenId) private nonReentrant {
        uint256 totalRewards;
        // Check statement should check ownership and already staked simultaneously
        require(_depositedIds[msg.sender].contains(tokenId), "Error: Not token owner");
        // Calculate rewards
        totalRewards = _earned(_depositedBlocks[tokenId], tokenId);
        // Update mappings
        _depositedIds[msg.sender].remove(tokenId);
        delete _depositedBlocks[tokenId];
        //Transfer NFT and reward tokens
        stakingToken.safeTransferFrom(address(this), msg.sender, tokenId);
        rewardToken.mintTo(msg.sender, totalRewards);

        emit NFTUnstaked(msg.sender, tokenId, block.timestamp);
    }

    /// @notice Internally calculates rewards
    /// @param timestamp Timestamp at time of deposit
    /// @param tokenId Staked token id
    function _earned(uint256 timestamp, uint256 tokenId) internal view returns (uint256) {
        if (timestamp == 0) return 0;
        uint256 rateForTokenId = rate + _rateModifiers[tokenId];
        uint256 end;
        if (endTime == 0) {
            // endtime not set, which is likely
            end = block.timestamp;
        } else {
            end = Math.min(block.timestamp, endTime);
        }
        if (timestamp > end) return 0;

        return ((end - timestamp) * rateForTokenId) / epochDuration;
    }

    /// @notice Update bee count in Hive for every deposit and withdraw
    /// @param hiveId The hive where the NFT is being deposited or withdrawn
    /// @param isQueen Is the NFT a queen or a worker
    /// @param isDeposit Boolean as whether the NFT is being deposited
    function updateBeeCountInHive(uint256 hiveId, bool isQueen, bool isDeposit) private view {
        HiveTraits memory hiveTraits = _hiveIdToHiveTraits[hiveId];
        if (isDeposit) {
            if (isQueen) {
                uint256 queens = hiveTraits.numberOfQueensStaked++;
                require(queens <= maxQueensPerHive, "Queen limit reached in hive");
            } else {
                uint256 workers = hiveTraits.numberOfWorkersStaked++;
                require(workers <= maxWorkersPerHive, "Worker limit reached in hive");
            }
        } else {
            if (isQueen) {
                hiveTraits.numberOfQueensStaked--;
            } else {
                hiveTraits.numberOfWorkersStaked--;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*  View Functions                                                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculate current total rewards for a given account
    /// @param account User's address
    function totalEarned(address account) external view returns (uint256[] memory rewards) {
        uint256 length = _depositedIds[account].length();
        rewards = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _depositedIds[account].at(i);
            rewards[i] = _earned(_depositedBlocks[tokenId], tokenId);
        }
    }

    /// @notice Retrieve all token ids deposited in a user's account
    /// @param account User's address
    function depositsOf(address account) external view returns (uint256[] memory ids) {
        uint256 length = _depositedIds[account].length();
        ids = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            ids[i] = _depositedIds[account].at(i);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Set the new token rewards rate
    /// @param newRate Emmission rate in wei
    function setRate(uint256 newRate) external onlyOwner {
        rate = newRate;
    }

    /// @notice Set new token rewards end time
    /// @param newEndTime End time of token yield. Probably won't be needed
    function setEndTime(uint256 newEndTime) external onlyOwner {
        endTime = newEndTime;
    }

    /// @notice Set a rate multiplier for a specific tokenId
    /// @param rateModifier The new multiplier to add to the rate
    function setRateModifier(uint256 tokenId, uint256 rateModifier) external onlyOwner {
        _rateModifiers[tokenId] = rateModifier;
    }

    /// @notice Set the new staking token contract address
    /// @param newStakingTokenAddress New staking token address
    function setNewStakingAddress(address newStakingTokenAddress) external onlyOwner {
        stakingToken = BuzzkillNFT(newStakingTokenAddress);
    }

    /// @notice Set the new reward token contract address
    /// @param newRewardTokenAddress New reward token address
    function setNewRewardTokenAddress(address newRewardTokenAddress) external onlyOwner {
        rewardToken = Honey(newRewardTokenAddress);
    }

    /// @notice Set new limit for worker bees per hive
    /// @param newMaxWorkersPerHive New limit for worker bees per hive
    function setMaxWorkersPerHive(uint256 newMaxWorkersPerHive) external onlyOwner {
        maxWorkersPerHive = newMaxWorkersPerHive;
    }

    /// @notice Set new limit for queen bees per hive
    /// @param newMaxQueensPerHive New imit for worker bees per hive
    function setMaxQueensPerHive(uint256 newMaxQueensPerHive) external onlyOwner {
        maxQueensPerHive = newMaxQueensPerHive;
    }

    /// @notice Set the new time for reward interval
    /// @param newRewardInterval New time for reward interval
    function setRewardInterval(uint256 newRewardInterval) external onlyOwner {
        rewardInterval = newRewardInterval;
    }

    function setEpochDuration(uint256 newEpochDuration) external onlyOwner {
        epochDuration = newEpochDuration;
    }

    /// @notice Add a new hive with the specified environment.
    /// @param _environment The environment type of the new hive.
    function addHive(Environments _environment, uint256 _hiveDefense) external whenPaused onlyOwner returns (bool) {
        require(
            _environment == Environments.fire || _environment == Environments.water || _environment == Environments.ice
                || _environment == Environments.sands || _environment == Environments.forest,
            "Error: Invalid environment"
        );
        uint256 newHiveId = currentHiveId++;

        _hiveIdToHiveTraits[newHiveId] = HiveTraits({
            hiveId: newHiveId,
            numberOfQueensStaked: 0,
            numberOfWorkersStaked: 0,
            hiveDefense: _hiveDefense,
            environment: _environment
        });
        return true;
    }

    /// @notice Delete a hive with the given hiveId.
    /// @param hiveId The unique identifier of the hive to be deleted.
    function deleteHive(uint256 hiveId) external whenPaused onlyOwner returns (bool) {
        // Hive must be empty of all bees before deleting it
        require(_hiveIdToHiveTraits[hiveId].numberOfQueensStaked == 0, "Queen still in the hive");
        require(_hiveIdToHiveTraits[hiveId].numberOfWorkersStaked == 0, "Worker still in the hive");
        delete _hiveIdToHiveTraits[hiveId];
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
