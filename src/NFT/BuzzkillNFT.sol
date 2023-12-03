// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC725} from "@vrc725/contracts/VRC725.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {VRC725Enumerable} from "@vrc725/contracts/extensions/VRC725Enumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BuzzkillNFT is VRC725, VRC725Enumerable, ReentrancyGuard, Pausable {
    ////////////////////////
    /// ERRORS
    ////////////////////////
    error MintPriceNotPaid();
    error MaxSupply();
    error WithdrawTransfer();

    ////////////////////////
    /// STATE VARIABLES
    ////////////////////////
    uint256 private currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public mintPrice;

    constructor(uint256 _mintPrice) {
        __VRC725_init("Buzzkill", "BZK", msg.sender);
        mintPrice = _mintPrice;
    }

    ////////////////////////
    /// FUNCTIONS
    ////////////////////////
    //??? Considering adding a uint256 parameter so the user has the option to purchase as many as they want
    function mintTo(address to) public payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.value != mintPrice) {
            revert MintPriceNotPaid();
        }
        uint256 newTokenId = ++currentTokenId;

        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _safeMint(to, newTokenId);

        return newTokenId;
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://<SOME HASH HERE>/";
    }

    function withdrawPayments(address payable payee) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    /**
     * @notice Updates the new price of minting a NFT
     * @param newMintPrice New price to mint a NFT
     */
    function UpdateMintPrice(uint256 newMintPrice) external onlyOwner nonReentrant returns (bool) {
        mintPrice = newMintPrice;
        return true;
    }

    /**
     * @dev Required override from VRC725.
     */
    function _estimateFee(uint256) internal view override returns (uint256) {
        return minFee();
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(VRC725, VRC725Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override(VRC725, VRC725Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
