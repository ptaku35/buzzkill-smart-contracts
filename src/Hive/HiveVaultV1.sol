// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Honey} from "../Honey/Honey.sol";
import {BuzzkillNFT} from "../NFT/BuzzkillNFT.sol";
import {TraitsState} from "../traits/TraitsState.sol";
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

    /// @notice Rewards emitted per day staked
    uint256 public rate;

    /// @notice Endtime of token rewards
    uint256 public endTime;

    /// @notice Staking token contract address
    BuzzkillNFT public stakingToken;

    /// @notice Rewards token contract address
    Honey public rewardToken;

    /// @notice Set of staked token Ids by address
    mapping(address => EnumerableSet.UintSet) internal _depositedIds;

    /// @notice Mapping of timestamps from each staked token id
    mapping(address => mapping(uint256 => uint256)) public _depositedBlocks;

    /// @notice Mapping of tokenIds to their rate modifier
    mapping(uint256 => uint256) public _rateModifiers;

    constructor(
        address initialOwner,
        address buzzkillNFT,
        address honey,
        uint256 initialRewardsRate
    ) Ownable(initialOwner) {
        stakingToken = BuzzkillNFT(buzzkillNFT);
        rewardToken = Honey(honey);
        rate = initialRewardsRate;        
        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    function deposit(uint256 tokenId) external whenNotPaused {}

    function withdraw(uint256 tokenId) external whenNotPaused {}

    function claim() external whenNotPaused {}

    function earned(address account) external view returns (uint256) {}

    function depositsOf(address account) external view returns (uint256) {}

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    function setRate(uint256 newRate) external onlyOwner {}

    function setEndTime(uint256 newEndTime) external onlyOwner {}

    function setRateModifier(uint256 tokenId, uint256 rateModifier) external onlyOwner {}

    function setNewStakingAddress(address newStakingAddress) external onlyOwner {}

    function setNewRewardTokenAddress(address newRewardToken) external onlyOwner {}

    /// @notice Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}
