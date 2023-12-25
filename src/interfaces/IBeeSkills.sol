// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IBeeSkills {

    enum Environments {
        fire,
        ice,
        sands,
        forest,
        water
    }

    /// @notice Upgrade the attack attribute of a bee
    /// @param tokenId The ID of the bee token
    /// @param addAttack The amount of attack to add
    function upgradeAttack(uint256 tokenId, uint256 addAttack) external;

    /// @notice Upgrade the defense attribute of a bee
    /// @param tokenId The ID of the bee token
    /// @param addDefense The amount of defense to add
    function upgradeDefense(uint256 tokenId, uint256 addDefense) external;

    /// @notice Upgrade the foraging attribute of a bee
    /// @param tokenId The ID of the bee token
    /// @param addForaging The amount of foraging to add
    function upgradeForaging(uint256 tokenId, uint256 addForaging) external;

    /// @notice Execute a raid on a hive
    /// @param tokenId The ID of the bee token
    /// @param hiveId The ID of the target hive
    /// @return True if the raid is successful, false otherwise
    function raidAHive(uint256 tokenId, uint256 hiveId) external payable returns (bool);

    /// @notice Retrieve if a bee token is a queen
    /// @param tokenId The ID of the bee token
    /// @return True if the bee is a queen, false otherwise
    function getIsQueen(uint256 tokenId) external view returns (bool);

    /// @notice Initialize the traits of a bee token
    /// @param tokenId The ID of the bee token
    /// @param _isQueen Whether the bee is a queen
    /// @param _environment The environment of the bee
    /// @return True if the initialization is successful, false otherwise
    function initializeBeeTraits(uint256 tokenId, bool _isQueen, Environments _environment) external returns (bool);

    /// @notice Pause the contract
    function pause() external;

    /// @notice Unpause the contract
    function unpause() external;
}

