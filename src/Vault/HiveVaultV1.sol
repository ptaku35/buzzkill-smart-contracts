// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IBuzzkillNFT} from "../interfaces/IBuzzkillNFT.sol";
import {IHoney} from "../interfaces/IHoney.sol";
import {IBeeSkills} from "../interfaces/IBeeSkills.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC721Receiver} from "@vrc725/contracts/interfaces/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title HiveVaultV1
 * @author Earendel Labs
 * @notice This contract controls the staking mechanism.
 *
 *  The contract tracks all the hives that NFTs can be staked as well as
 *  the staking mechanics for each hive.
 *
 *  Each hive has a rate multiplier (RM). Users stake their bee in whatever
 *  hive they choose. They can claim rewards based on time staked multiplied by
 *  the hive RM. There is a lock-up period for staking. RM is based on the number
 *  of bees in the hive at the end of each epoch.
 * 
 *  For mainnet, this approach will be replaced with "hive pools", where each hive
 *  will have a pool of reward tokens that accumulate over time.  Staked bees will
 *  be entitled to a percentage of the reward token pool.  Users can "raid" a hive
 *  to steal tokens from the hive pool.
 */

//
contract HiveVaultV1 is IERC721Receiver, Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Give more weight to time staked; 10 is just an arbitrary place holder for now
    uint8 TIME_WEIGHTED_BONUS = 10;

    /// @notice Ratio of the value of a queen to a worker
    uint256 private constant QUEEN_TO_WORKER_RATIO = 5;

    /// @notice Id assigned to a hive
    uint256 private currentHiveId;

    /// @notice Rewards emitted per day staked in wei
    uint256 private rate;

    /// @notice Endtime of token rewards
    uint256 private endTime;

    /// @notice Limit of worker bees per hive
    uint256 private maxWorkersPerHive;

    /// @notice Limit of queen bees per hive
    uint256 private maxQueensPerHive;

    /// @notice Lock-up time after depositing NFT
    uint256 private lockUpDuration;

    /// @notice Time of a single epoch
    uint256 private epochDuration;

    /// @notice Current Epoch timestamp
    uint256 private currentEpochTimestamp;

    /// @notice Set of existing Hive Ids
    EnumerableSet.UintSet private allHiveIds;

    /// @notice Staking token contract address
    IBuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    IHoney public rewardToken;

    /// @notice Bee traits contract address
    IBeeSkills public beeSkills;

    /// @notice Set of staked token Ids by address
    mapping(address user => EnumerableSet.UintSet stakedTokenIds) private _depositedIds;

    /// @notice Mapping of timestamps from each staked token id
    mapping(uint256 tokenId => uint256 timestamp) private _depositedBlocks;

    /// @notice Mapping of hive to its hive traits
    mapping(uint256 hiveId => HiveTraits hiveTraits) public _hiveIdToHiveTraits;

    /// @notice Mapping of every staked token in each hive
    mapping(uint256 hiveId => EnumerableSet.UintSet stakedTokenIds) private _hiveIdToStakedTokens;

    /// @notice Mapping of staking token to its staked hive
    mapping(uint256 tokenId => uint256 hiveId) public _tokenIdToHiveId;

    ///@notice Mapping to store the lock-up expiration timestamp for each NFT
    mapping(uint256 tokenId => uint256 lockUpExpiration) public _lockUpExpirationTimestamp;

    /// @notice Different hive environments
    enum Environments {
        fire,
        ice,
        sands,
        forest,
        water
    }

    /// @notice Struct representing traits of a hive
    struct HiveTraits {
        uint256 hiveId;
        uint256 rateMultiplier;
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
        address beeSkills_,
        uint256 rate_,
        uint256 maxQueensPerHive_,
        uint256 maxWorkersPerHive_,
        uint256 epochDuration_,
        uint256 lockUpDuration_
    ) Ownable(initialOwner) {
        stakingToken = IBuzzkillNFT(buzzkillNFT);
        rewardToken = IHoney(honey);
        beeSkills = IBeeSkills(beeSkills_);
        rate = rate_;
        maxWorkersPerHive = maxWorkersPerHive_;
        maxQueensPerHive = maxQueensPerHive_;
        epochDuration = epochDuration_;
        lockUpDuration = lockUpDuration_;
        currentEpochTimestamp = block.timestamp;
        // _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Stake the specified NFT (`tokenId`) into the hive with the given ID (`hiveId`).
    /// @param tokenId The unique identifier of the NFT to be staked.
    /// @param hiveId The ID of the hive where the NFT will be staked.
    function stakeBee(uint256 tokenId, uint256 hiveId) external whenNotPaused returns (bool) {
        // Add the new deposit to the mapping and check that NFT is not already staked
        bool success = _depositedIds[msg.sender].add(tokenId);
        require(success, "NFT already staked");
        require(msg.sender == stakingToken.ownerOf(tokenId), "Error: Only token owner can stake");
        require(hiveId <= currentHiveId && hiveId > 0, "Error: Invalid hive ID");

        _tokenIdToHiveId[tokenId] = hiveId;
        _lockUpExpirationTimestamp[tokenId] = block.timestamp + lockUpDuration;
        _hiveIdToStakedTokens[hiveId].add(tokenId);
        _updateBeeCountInHive(hiveId, beeSkills.getIsQueen(tokenId), true);

        _deposit(tokenId);
        return true;
    }

    /// @notice Unstake a bee NFT and claim rewards based on the time it has been staked.
    /// @dev The caller must be the owner of the NFT and the NFT must be currently staked.
    /// @param tokenId The unique identifier of the bee NFT to be unstaked and claimed.
    function unstakeBee(uint256 tokenId) external whenNotPaused returns (bool) {
        // Check statement simultaneously checks ownership and if already staked
        require(_depositedIds[msg.sender].contains(tokenId), "Error: Not token owner or NFT not staked");
        require(_lockUpExpired(tokenId), "Lock-up period not expired");

        uint256 hiveId = _tokenIdToHiveId[tokenId];

        _updateBeeCountInHive(hiveId, beeSkills.getIsQueen(tokenId), false);
        _hiveIdToStakedTokens[hiveId].remove(tokenId);
        delete _tokenIdToHiveId[tokenId];
        _depositedIds[msg.sender].remove(tokenId);
        delete _depositedBlocks[tokenId];

        _withdraw(tokenId);
        return true;
    }

    /// @notice Claim pending token rewards
    function claim() external whenNotPaused nonReentrant {
        uint256 totalRewards;
        uint256 length = _depositedIds[msg.sender].length();
        uint256 tokenId;
        for (uint256 i = 0; i < length; i++) {
            tokenId = _depositedIds[msg.sender].at(i);

            // Calculate total rewards if lock-up expired
            if (_lockUpExpired(tokenId)) {
                totalRewards += _earned(_depositedBlocks[tokenId], tokenId);
                // Update last checkpoint
                _depositedBlocks[tokenId] = block.timestamp;
            }
        }
        // Mint new tokens
        rewardToken.mintTo(msg.sender, totalRewards);

        emit Claimed(msg.sender, block.timestamp);
    }

    /* -------------------------------------------------------------------------- */
    /*  Private/Internal Functions                                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Deposit tokens into the vault
    /// @param tokenId Token to be deposited
    function _deposit(uint256 tokenId) private nonReentrant {

        // Set timestamp for tokenId
        _depositedBlocks[tokenId] = block.timestamp;

        // Transfer the deposited token to this contract
        stakingToken.safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTStaked(msg.sender, tokenId, block.timestamp);
    }

    /// @notice Withdraw tokens and claim their pending rewards
    /// @param tokenId Staked token Id
    function _withdraw(uint256 tokenId) private nonReentrant {
        // Calculate rewards
        uint256 totalRewards;
        totalRewards = _earned(_depositedBlocks[tokenId], tokenId);
        
        //Transfer NFT and reward tokens
        stakingToken.safeTransferFrom(address(this), msg.sender, tokenId);
        rewardToken.mintTo(msg.sender, totalRewards);

        emit NFTUnstaked(msg.sender, tokenId, block.timestamp);
    }

    /// @notice Internally calculates rewards
    /// @param timestamp Timestamp at time of deposit
    /// @param tokenId Staked token id
    function _earned(uint256 timestamp, uint256 tokenId) private view returns (uint256) {
        if (timestamp == 0) return 0;
        uint256 hiveRateMultiplier = _hiveIdToHiveTraits[_tokenIdToHiveId[tokenId]].rateMultiplier;
        uint256 rateForTokenId = rate * hiveRateMultiplier;
        uint256 end;
        if (endTime == 0) {
            // endtime not set, which is likely
            end = block.timestamp;
        } else {
            end = Math.min(block.timestamp, endTime);
        }
        if (timestamp > end) return 0;

        return ((end - timestamp) * rateForTokenId) * TIME_WEIGHTED_BONUS / epochDuration;
    }

    /// @notice Update bee count in Hive for every deposit and withdraw
    /// @param hiveId The hive where the NFT is being deposited or withdrawn
    /// @param isQueen Is the NFT a queen or a worker
    /// @param isDeposit Boolean as whether the NFT is being deposited
    function _updateBeeCountInHive(uint256 hiveId, bool isQueen, bool isDeposit) private {
        // int8 addSubtractOne = isDeposit ? int8(1) : int8(-1);
        if (isDeposit) {
            // Add to hive
            if (isQueen) {
                uint256 queens = _hiveIdToHiveTraits[hiveId].numberOfQueensStaked++;
                require(queens <= maxQueensPerHive, "Queen limit reached in hive");
            } else {
                uint256 workers = _hiveIdToHiveTraits[hiveId].numberOfWorkersStaked++;
                require(workers <= maxWorkersPerHive, "Worker limit reached in hive");
            }
        } else {
            // Subtract from hive
            if (isQueen) {
                _hiveIdToHiveTraits[hiveId].numberOfQueensStaked--;
            } else {
                _hiveIdToHiveTraits[hiveId].numberOfWorkersStaked--;
            }
        }
    }

    function _lockUpExpired(uint256 tokenId) private view returns (bool) {
        return block.timestamp > _lockUpExpirationTimestamp[tokenId];
    }

    function _calculateHiveRateMultiplier(uint256 hiveId) private view returns (uint256 newRateMultiplier) {
        HiveTraits memory hive = _hiveIdToHiveTraits[hiveId];
        uint256 queens = hive.numberOfQueensStaked;
        uint256 workers = hive.numberOfWorkersStaked;
        newRateMultiplier = queens * QUEEN_TO_WORKER_RATIO + workers;
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

    /// @notice Retrieve Hive traits for a given hive Id
    function getHiveTraits(uint256 hiveId) external view returns (HiveTraits memory) {
        return _hiveIdToHiveTraits[hiveId];
    }

    /// @notice Get all the token Ids staked in a hive
    /// @dev Need to retrieve a list of staked tokens in a hive for the frontend display
    /// @param hiveId Hive to retrieve all token IDs staked
    function getStakedTokensInAHive(uint256 hiveId) external view returns(uint256[] memory) {
        uint256 length = _hiveIdToStakedTokens[hiveId].length();
        uint256[] memory stakedTokens = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            stakedTokens[i] = _hiveIdToStakedTokens[hiveId].at(i);
        }

        return stakedTokens;
    }

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Update rate multiplier for each hive
    /// @dev Rate multipliers gets updated once every epoch
    /// @dev Needs to be called off-chain
    function updateAllHiveRateMultipliers() external onlyOwner {
        require(block.timestamp >= currentEpochTimestamp + epochDuration, "Too soon to update");
        uint256 length = allHiveIds.length();
        uint256 hiveId;
        // Set new rate multiplier for all existing hives
        for (uint256 i = 0; i < length; i++) {
            _hiveIdToHiveTraits[hiveId].rateMultiplier = _calculateHiveRateMultiplier(allHiveIds.at(i));
        }
        currentEpochTimestamp = block.timestamp;
    }

    /// @notice Update rate multiplier for a single hive
    /// @dev Used for raiding mechanics in BeeSkills.sol
    function updateSingleHiveRateMultiplier(uint256 hiveId, uint256 newRateMultiplier) external onlyOwner {
        _hiveIdToHiveTraits[hiveId].rateMultiplier = newRateMultiplier;
    }

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

    /// @notice Set the new staking token contract address
    /// @param newStakingTokenAddress New staking token address
    function setNewStakingAddress(address newStakingTokenAddress) external onlyOwner {
        stakingToken = IBuzzkillNFT(newStakingTokenAddress);
    }

    /// @notice Set the new reward token contract address
    /// @param newRewardTokenAddress New reward token address
    function setNewRewardTokenAddress(address newRewardTokenAddress) external onlyOwner {
        rewardToken = IHoney(newRewardTokenAddress);
    }
    
    /// @notice Set the new Beeskills contract address
    /// @param newBeeskillsAddress New reward token address
    function setNewBeeskillsAddress(address newBeeskillsAddress) external onlyOwner {
        beeSkills = IBeeSkills(newBeeskillsAddress);
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

    /// @notice Set new lock up duration for staking NFTs
    /// @param newLockUpDuration New minimum time NFTs must be staked
    function setLockUpDuration(uint256 newLockUpDuration) external onlyOwner {
        lockUpDuration = newLockUpDuration;
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
        allHiveIds.add(newHiveId);

        _hiveIdToHiveTraits[newHiveId] = HiveTraits({
            hiveId: newHiveId,
            rateMultiplier: 0,
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
        allHiveIds.remove(hiveId);
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

    /// @notice allow vault contract (address(this)) to receive VRC725 tokens
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // amount
        bytes calldata //data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
