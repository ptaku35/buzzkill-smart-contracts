// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// import {IHive} from "./IHive.sol";
import {Honey} from "../Honey/Honey.sol";
import {BuzzkillNFT} from "../NFT/BuzzkillNFT.sol";
import {TraitsState} from "../traits/TraitsState.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * TODO list
 * 1. Correctly calculate claimable rewards - function unstakeBeeAndClaimRewards
 * 2. Need a function to check for remaining Queens in the hive and update APR accordingly - function unstakeBeeAndClaimRewards
 * 3. Correctly pop the usersStakedBees array when unstaking NFT - function unstakeBeeAndClaimRewards //? Actually considering deleting this as it takes a lot of gas
 * 4. Implement function viewAmountOfClaimableTokens
 * 5. Implement function calculateClaimableTokens
 * 6. Refactor any functions and add additional functions to perform logic where it can be done.
 * 7. Claim vs Unstake???
 * 8. Incorporate unused variables i.e. maxNumberOfWorkersThatCanBeStakedPerHive
 * 9. Consider raiding mechanics in Hive contract
 */

contract Hive is TraitsState, Ownable, ReentrancyGuard, Pausable {

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */

    uint256 private constant maxWorkersPerHive = 20; //* Unused so far, may delete for now
    uint256 private constant maxQueensPerHive = 3; //* Unused so far, may delete for now
    uint256 totalStakedNFTs;
    uint256 private currentHiveId;

    BuzzkillNFT buzzkillNFT;
    Honey honey;

    mapping(uint256 tokenId => uint256 hiveId) public tokenIdToHiveId;
    mapping(address user => uint256[] stakedBees) public usersStakedBees;
    mapping(uint256 hiveId => HiveTraits hiveTraits) public hiveIdToHiveTraits;
    mapping(uint256 tokenId => Stake) private vault;

    //? Considering an array for tracking all addresses that have staked tokens

    struct Stake {
        uint24 tokenId;
        uint24 hiveId;
        uint48 timeStamp;
        address nftOwner;
    }

    /* -------------------------------------------------------------------------- */
    /*  Events                                                                    */
    /* -------------------------------------------------------------------------- */
    event NFTStaked(address indexed owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address indexed owner, uint256 tokenId, uint256 value);
    event Claimed(address nftOwner, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                         Logic Functions                                    */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _buzzkillNFTAddress, 
        address _honeyAddress, 
        address _initialOwner
        ) Ownable(_initialOwner) {
        buzzkillNFT = BuzzkillNFT(_buzzkillNFTAddress);
        honey = Honey(_honeyAddress);
    }

    /**
     * @notice Stake the specified NFT (`tokenId`) into the hive with the given ID (`hiveId`).
     * @dev This function is used for staking NFTs.
     * @param tokenId The unique identifier of the NFT to be staked.
     * @param hiveId The ID of the hive where the NFT will be staked.
     */
    function stakeBee(uint256 tokenId, uint256 hiveId) external nonReentrant whenNotPaused returns (bool) {
        BeeTraits memory beeTraits = tokenIdToBeeTraits[tokenId];
        require(msg.sender == buzzkillNFT.ownerOf(tokenId), "Error: Only token owner can stake");
        require(!beeTraits.isBeeStaked, "Error: NFT has already been staked");
        require(hiveId <= currentHiveId && hiveId > 0, "Error: Invalid hive ID");
        require(currentHiveId > 0, "Error: No Hives have been created");

        // Update vault mapping
        vault[tokenId] = Stake({
            tokenId: uint24(tokenId),
            hiveId: uint24(hiveId),
            timeStamp: uint48(block.timestamp),
            nftOwner: msg.sender
        });

        // Update Hive traits
        HiveTraits memory hiveTraits = hiveIdToHiveTraits[hiveId];
        if (beeTraits.isQueen) {
            hiveTraits.numberOfQueensStaked++;
        } else {
            hiveTraits.numberOfWorkersStaked++;
        }

        // Update mapping and variables
        totalStakedNFTs++;
        tokenIdToHiveId[tokenId] = hiveId;
        usersStakedBees[msg.sender].push(tokenId);
        beeTraits.isBeeStaked = true;

        // Transfer NFT to this Hive contract
        buzzkillNFT.transferFrom(msg.sender, address(this), tokenId);

        // Emit event
        emit NFTStaked(msg.sender, tokenId, block.timestamp);

        return true;
    }

    /**
     * @notice Unstake a bee NFT and claim rewards based on the time it has been staked.
     * @dev The caller must be the owner of the NFT and the NFT must be currently staked.
     * @param tokenId The unique identifier of the bee NFT to be unstaked and claimed.
     * @return A boolean indicating the success of the unstaking and reward claiming process.
     */
    function unstakeBeeAndClaimRewards(uint256 tokenId) external nonReentrant whenNotPaused returns (bool) {
        BeeTraits memory beeTraits = tokenIdToBeeTraits[tokenId];
        require(msg.sender == vault[tokenId].nftOwner, "Error: Only token owner can unstake");
        require(beeTraits.isBeeStaked, "Error: NFT is not staked");

        // Update Hive traits
        HiveTraits memory hiveTraits = hiveIdToHiveTraits[vault[tokenId].hiveId];
        if (beeTraits.isQueen) {
            hiveTraits.numberOfQueensStaked--;
        } else {
            hiveTraits.numberOfWorkersStaked--;
        }

        //! 2

        // Update mapping and variables
        totalStakedNFTs--;
        delete tokenIdToHiveId[tokenId];
        beeTraits.isBeeStaked = false;
        // usersStakedBees[msg.sender].push(tokenId); //! 3

        // Calculate amount of claimable rewards and mint to user //! 1
        uint256 earnedAmount = 10 * (block.timestamp - vault[tokenId].timeStamp);
        if (earnedAmount > 0) {
            honey.mintTo(msg.sender, earnedAmount / 10_000);
        }

        // Transfer NFT
        buzzkillNFT.transferFrom(address(this), msg.sender, tokenId);

        // Update vault mapping
        delete vault[tokenId];

        // Mark NFT as unstaked and emit event
        emit NFTUnstaked(msg.sender, tokenId, block.timestamp);

        return true;
    }

    function claimRewardsFromHivePool() external {}

    /**
     * @notice Get the amount of claimable rewards for a given user.
     * @param user The address of the user for whom the claimable rewards are queried.
     * @return The amount of claimable rewards in tokens for the specified user.
     */
    function viewAmountOfClaimableTokens(address user) external view returns (uint256) { //! 4
            // return calculateClaimableTokens();
    }

    /* -------------------------------------------------------------------------- */
    /*                         Owner Functions                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Add a new hive with the specified environment.
     * @dev Only the contract owner can add a new hive.
     * @param _environment The environment type of the new hive.
     * @return A boolean indicating the success of the hive addition.
     */
    function addHive(Environments _environment, uint256 _hiveDefense) external onlyOwner returns (bool) {
        //
        require(
            _environment == Environments.fire || _environment == Environments.water || _environment == Environments.ice
                || _environment == Environments.desert || _environment == Environments.forest,
            "Error: Invalid environment"
        );

        uint256 newHiveId = currentHiveId++;
        hiveIdToHiveTraits[newHiveId] = HiveTraits({
            hiveId: newHiveId,
            numberOfQueensStaked: 0,
            numberOfWorkersStaked: 0,
            hiveDefense: _hiveDefense,
            environment: _environment
        });

        return true;
    }

    /**
     * @notice Delete a hive with the given hiveId.
     * @dev Only the contract owner can delete a hive.
     * @param hiveId The unique identifier of the hive to be deleted.
     * @return A boolean indicating the success of the hive deletion.
     */
    function deleteHive(uint256 hiveId) external onlyOwner returns (bool) {
        delete hiveIdToHiveTraits[hiveId];
        return true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //! 5
    function calculateClaimableTokens() private returns (uint256) {}

    function raidAHive(uint256 tokenId, uint256 hiveId) external returns (bool) {
        // require ownership tokenId
        // require("Can't raid your own hive")
        // require("Not enough energy") or "Already raided today"

        // Add a cost to raid
        // Check that tokenId owner has honey to pay for raid
        // honey.transferFrom(msg.sender, toSomeAddress, 10 tokens) // Need to make sure this contract is authorized to transfer from user's account
        // Could burn some, could send some to hive, could send some to a general account (ecosystem), maybe revenue

        // Attack Mechanics
        // Need BeeTraits - Attack
        // Need Hive defense - call HiveTraits
        // random number generator
        // RN needs to be less than the attack - defense to be successful
        // update any BeeTraits such as energy, cooldown time, etc

        // If raid fails, do:
        // do nothing, return fail
        // If raid succeeds, do:
        // Take $honey from the raided Hive
        // Amount will be some percent of the total Hive pool

        // Future Iterations:
        // VRF
        // Allocate some honey to wallet and HivePool
        // Luck powerup - pay for powerup, increases raid success probability
        // Account for Hive or bee environment
    }
}
