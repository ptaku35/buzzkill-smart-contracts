// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// import {IHive} from "./IHive.sol";
import {BuzzkillNFT} from "../BuzzkillNFT.sol";
import {Honey} from "../Honey/Honey.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TraitsState} from "../traits/TraitsState.sol";


contract Hive is TraitsState, Ownable, ReentrancyGuard {
    ////////////////////////
    /// STATE VARIABLES
    ////////////////////////
    uint256 maxNumberOfWorkersThatCanBeStakedPerHive;
    uint256 maxNumberOfQueensThatCanBeStakedPerHive;
    uint256 totalStakedNFTs;
    uint256 private currentHiveId;

    BuzzkillNFT buzzkillNFT;
    Honey honey;

    ////////////////////////
    /// MAPPINGS/DATA STRUCTS
    ////////////////////////
    mapping(uint256 tokenId => uint256 hiveId) public tokenIdToHiveId;
    mapping(address user => uint256[] stakedBees) public usersStakedBees;
    mapping(uint256 hiveId => HiveTraits hiveTraits) public hiveIdToHiveTraits;
    mapping(uint256 tokenId => Stake) private vault;

    struct HiveTraits {
        uint256 hiveId;
        uint256 numberOfQueensStaked;
        uint256 numberOfWorkersStaked;
        Environments environment;
    }

    struct Stake {
        uint24 tokenId;
        uint24 hiveId;
        uint48 timeStamp;
        address nftOwner;
    }

    ////////////////////////
    /// EVENTS
    ////////////////////////
    event NFTStaked(address indexed owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address indexed owner, uint256 tokenId, uint256 value);
    event Claimed(address nftOwner, uint256 amount);

    ////////////////////////
    /// FUNCTIONS
    ////////////////////////
    constructor(address _buzzkillNFTAddress, address _honeyAddress) Ownable(msg.sender) {
        buzzkillNFT = BuzzkillNFT(_buzzkillNFTAddress);
        honey = Honey(_honeyAddress);
    }

    /**
     * @notice Stake the specified NFT (`tokenId`) into the hive with the given ID (`hiveId`).
     * @dev This function is used for staking NFTs.
     * @param tokenId The unique identifier of the NFT to be staked.
     * @param hiveId The ID of the hive where the NFT will be staked.
     */
    function stakeBee(uint256 tokenId, uint256 hiveId) external nonReentrant returns (bool) {
        BeeTraits memory beeTraits = tokenIdToBeeTraits[tokenId];

        require(msg.sender == buzzkillNFT.ownerOf(tokenId), "Error: Only the NFT owner can stake");
        require(!beeTraits.isBeeStaked, "Error: NFT has already been staked");
        require(hiveId <= currentHiveId && hiveId > 0, "Error: Invalid hive ID");
        require(currentHiveId > 0, "Error: No Hives have been created");

        // Transfer NFT to this Hive contract
        buzzkillNFT.transferFrom(msg.sender, address(this), tokenId);

        // Update vault mapping
        vault[tokenId] = Stake({
            tokenId: uint24(tokenId),
            hiveId: uint24(hiveId),
            timeStamp: uint48(block.timestamp),
            nftOwner: msg.sender
        });

        // Update Hive traits
        if (beeTraits.isQueen) {

        }

        // Update mapping and variables
        totalStakedNFTs++;
        tokenIdToHiveId[tokenId] = hiveId;
        usersStakedBees[msg.sender].push(tokenId);

        // Mark NFT as staked and emit event
        tokenIdToBeeTraits[tokenId].isBeeStaked = true;
        emit NFTStaked(msg.sender, tokenId, block.timestamp);

        return true;
    }

    function unstakeBee(uint256 tokenId) external nonReentrant returns (bool) {
        BeeTraits memory beeTraits = tokenIdToBeeTraits[tokenId];

        require(msg.sender == buzzkillNFT.ownerOf(tokenId), "Error: Only the NFT owner can unstake");
        require(tokenIdToBeeTraits[tokenId].isBeeStaked, "Error: NFT is not staked");

        // Transfer NFT

        // Update vault mapping

        // Update Hive traits

        // Update mapping and variables
        totalStakedNFTs--;


        // Mark NFT as unstaked and emit event
        beeTraits.isBeeStaked = false;
        emit NFTUnstaked(msg.sender, tokenId, block.timestamp);

        return true;
    }

    function addHive(Environments _environment) external onlyOwner returns (bool) {
        uint256 newHiveId = currentHiveId++;
        hiveIdToHiveTraits[newHiveId] =
            HiveTraits({
                hiveId: newHiveId, 
                numberOfQueensStaked: 0, 
                numberOfWorkersStaked: 0, 
                environment: _environment
            });

        return true;
    }

    function deleteHive(uint256 hiveId) external onlyOwner {
        delete hiveIdToHiveTraits[hiveId];
    }

    function getHiveTraits(uint24 hiveId) external view returns (HiveTraits memory) {
        return hiveIdToHiveTraits[hiveId];
    }

    function getUsersStakedNfts(address user) external view returns (uint256[] memory _beesStaked) {

    }
}
