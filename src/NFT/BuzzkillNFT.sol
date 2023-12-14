// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC725} from "@vrc725/contracts/VRC725.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {VRC725Enumerable} from "@vrc725/contracts/extensions/VRC725Enumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// 888888b.   888     888 8888888888P 8888888888P 888    d8P  8888888 888      888
// 888  "88b  888     888       d88P        d88P  888   d8P     888   888      888
// 888  .88P  888     888      d88P        d88P   888  d8P      888   888      888
// 8888888K.  888     888     d88P        d88P    888d88K       888   888      888
// 888  "Y88b 888     888    d88P        d88P     8888888b      888   888      888
// 888    888 888     888   d88P        d88P      888  Y88b     888   888      888
// 888   d88P Y88b. .d88P  d88P        d88P       888   Y88b    888   888      888
// 8888888P"   "Y88888P"  d8888888888 d8888888888 888    Y88b 8888888 88888888 88888888

contract BuzzkillNFT is VRC725, VRC725Enumerable, ReentrancyGuard, Pausable {
    /* -------------------------------------------------------------------------- */
    /*  Errors                                                                    */
    /* -------------------------------------------------------------------------- */
    error MintPriceTooLow();
    error MintPriceTooHigh();
    error MintPriceNotPaid();
    error MaxSupply();
    error WithdrawTransfer();

    /* -------------------------------------------------------------------------- */
    /* State Variables                                                            */
    /* -------------------------------------------------------------------------- */
    uint256 public currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public mintPrice;

    /* -------------------------------------------------------------------------- */
    /*  Constructor                                                               */
    /* -------------------------------------------------------------------------- */

    constructor(uint256 _mintPrice) {
        // TODO: Need a modifier here for this and the updateMintPrice function
        // TODO: Maybe need to consider more strongly about the mint price requirements
        if (_mintPrice < 0.00044 ether) revert MintPriceTooLow();
        if (_mintPrice > 5 ether) revert MintPriceTooHigh();
        __VRC725_init("Buzzkill", "BZK", msg.sender);
        mintPrice = _mintPrice;
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    // TODO: Considering adding a uint256 parameter so the user has the option to purchase as many as they want
    // TODO: Consider best way to handle mint cost
    function mintTo(address to) external payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.sender != owner()) {
            if (msg.value != mintPrice) revert MintPriceNotPaid();
        }

        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) revert MaxSupply();

        _safeMint(to, newTokenId);

        return newTokenId;
    }

    function burn(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _burn(tokenId);
    }

    // TODO: Add base URI
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://<SOME HASH HERE>/";
    }

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    function withdrawPayments(address payable payee) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");

        if (!transferTx) revert WithdrawTransfer();
    }

    /// @notice Updates the new price of minting a NFT
    /// @param newMintPrice New price to mint a NFT
    /// @return A boolean indicating the success of the function
    function UpdateMintPrice(uint256 newMintPrice) external onlyOwner returns (bool) {
        if (newMintPrice < 0.00044 ether) revert MintPriceTooLow();
        if (newMintPrice > 5 ether) revert MintPriceTooHigh();
        mintPrice = newMintPrice;
        return true;
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Required Overrides                                                        */
    /* -------------------------------------------------------------------------- */

    /// @dev Required override from VRC725.
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
