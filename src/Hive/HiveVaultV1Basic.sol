// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Honey} from "../Honey/Honey.sol";
import {BuzzkillNFT} from "../NFT/BuzzkillNFT.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Hive Vault
contract HiveVaultV1Basic is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Rewards emitted per day staked
    uint256 public rate;

    /// @notice Endtime of token rewards
    uint256 public endTime;

    /// @notice Staking token contract address
    BuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    Honey public rewardToken;

    /// @notice Set of staked token Ids by address
    mapping(address user => EnumerableSet.UintSet stakedTokens) internal _depositedIds;

    /// @notice Mapping of timestamps from each staked token id
    mapping(address => mapping(uint256 => uint256)) public _depositedBlocks;

    /// @notice Set of hives mapped to token Ids and their timestamps
    mapping(uint256 => mapping(uint256 => uint256)) public _hiveIdToTokenIdAndTimestamps;

    /// @notice Mapping of tokenIds to their rate modifier
    mapping(uint256 => uint256) public _rateModifiers;

    /* -------------------------------------------------------------------------- */
    /*  Constructor                                                               */
    /* -------------------------------------------------------------------------- */

    constructor(address initialOwner, address buzzkillNFT, address honey, uint256 initialRewardsRate)
        Ownable(initialOwner)
    {
        stakingToken = BuzzkillNFT(buzzkillNFT);
        rewardToken = Honey(honey);
        rate = initialRewardsRate;
        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @dev This function does not make any checks!
    /// @notice Deposit tokens into the vault
    /// @param tokenId Token to be deposited
    function deposit(uint256 tokenId) external whenNotPaused {
        // Add the new deposit to the mapping
        _depositedIds[msg.sender].add(tokenId);
        _depositedBlocks[msg.sender][tokenId] = block.timestamp;

        // Transfer the deposited token to this contract
        stakingToken.transferFrom(msg.sender, address(this), tokenId);
    }

    /// @notice Withdraw tokens and claim their pending rewards
    /// @param tokenId Staked token Id
    function withdraw(uint256 tokenId) external whenNotPaused {
        uint256 totalRewards;
        require(_depositedIds[msg.sender].contains(tokenId), "Error: Not token owner");
        // Calculate rewards
        totalRewards = _earned(_depositedBlocks[msg.sender][tokenId], tokenId);

        // Update mappings
        _depositedIds[msg.sender].remove(tokenId);
        delete _depositedBlocks[msg.sender][tokenId];

        //Transfer NFT and reward tokens
        stakingToken.safeTransferFrom(address(this), msg.sender, tokenId);
        rewardToken.mintTo(msg.sender, totalRewards);
    }

    /// @notice Claim pending token rewards
    function claim() external whenNotPaused {
        uint256 totalRewards;
        uint256 length = _depositedIds[msg.sender].length();
        uint256 tokenId;
        for (uint256 i = 0; i < length; i++) {
            // Calculate total rewards
            tokenId = _depositedIds[msg.sender].at(i);
            totalRewards += _earned(_depositedBlocks[msg.sender][tokenId], tokenId);
            // Update last checkpoint
            _depositedBlocks[msg.sender][tokenId] = block.timestamp;
        }
        // Mint new tokens
        rewardToken.mintTo(msg.sender, totalRewards);
    }

    /* -------------------------------------------------------------------------- */
    /*  View Functions                                                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculate total rewards for a given account
    /// @param account User's address
    function totalEarned(address account) external view returns (uint256[] memory rewards) {
        uint256 length = _depositedIds[account].length();
        rewards = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _depositedIds[account].at(i);
            rewards[i] = _earned(_depositedBlocks[account][tokenId], tokenId);
        }
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

        return ((end - timestamp) * rateForTokenId) / 1 days;
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

    /// @notice Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}
