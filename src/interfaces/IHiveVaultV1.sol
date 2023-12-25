
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IHiveVaultV1 {

    // Enum and struct definitions
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

    // Event definitions
    event NFTStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event Claimed(address indexed nftOwner, uint256 amount);

    // Function signatures
    function _tokenIdToHiveId(uint256 tokenId) external view returns (uint256);
    function stakeBee(uint256 tokenId, uint256 hiveId) external returns (bool);
    function unstakeBee(uint256 tokenId) external returns (bool);
    function claim() external;
    function totalEarned(address account) external view returns (uint256[] memory rewards);
    function depositsOf(address account) external view returns (uint256[] memory ids);
    function getHiveTraits(uint256 hiveId) external view returns (HiveTraits memory);
    function getStakedTokensInAHive(uint256 hiveId) external view returns(uint256[] memory);
    function updateAllHiveRateMultipliers() external;
    function updateSingleHiveRateMultiplier(uint256 hiveId, uint256 newRateMultiplier) external;
    function setRate(uint256 newRate) external;
    function setEndTime(uint256 newEndTime) external;
    function setNewStakingAddress(address newStakingTokenAddress) external;
    function setNewRewardTokenAddress(address newRewardTokenAddress) external;
    function setNewBeeskillsAddress(address newBeeskillsAddress) external;
    function setMaxWorkersPerHive(uint256 newMaxWorkersPerHive) external;
    function setMaxQueensPerHive(uint256 newMaxQueensPerHive) external;
    function setLockUpDuration(uint256 newLockUpDuration) external;
    function setEpochDuration(uint256 newEpochDuration) external;
    function addHive(Environments _environment, uint256 _hiveDefense) external returns (bool);
    function deleteHive(uint256 hiveId) external returns (bool);
    function pause() external;
    function unpause() external;
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);
}
