// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC725} from "@vrc725/contracts/VRC725.sol";
import {VRC725Enumerable} from "@vrc725/contracts/extensions/VRC725Enumerable.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
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
    error MaxSupplyExceeded();
    error WithdrawTransferFailed();

    /* -------------------------------------------------------------------------- */
    /* State Variables                                                            */
    /* -------------------------------------------------------------------------- */
    uint256 public currentTokenId;
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public mintPrice;

    /* -------------------------------------------------------------------------- */
    /*  Constructor                                                               */
    /* -------------------------------------------------------------------------- */

    constructor(uint256 _mintPrice) {
        if (_mintPrice < 1 ether) revert MintPriceTooLow(); // ether is just a conversion to 10e18, not literally ether
        if (_mintPrice > 100 ether) revert MintPriceTooHigh();
        __VRC725_init("Buzzkill", "BZK", msg.sender);
        mintPrice = _mintPrice;
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Mints a new token to a specified address
    /// @param to The address to mint the token to
    /// @return The tokenId of the newly minted token
    function mintTo(address to) external payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.sender != owner()) { // Will delete this requirement on mainnet
            if (msg.value != mintPrice) revert MintPriceNotPaid();
        }
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > MAX_SUPPLY) revert MaxSupplyExceeded();

        _safeMint(to, newTokenId);

        return newTokenId;
    }

    /// @notice Burns a token with a specified tokenId
    /// @dev Can only be called by the contract owner
    /// @param tokenId The tokenId of the token to be burned
    function burn(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _burn(tokenId);
    }

    /// @notice Returns the base URI for the token metadata
    /// @dev Override to return the custom base URI for this contract
    /// @return The base URI string
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeiayhxazprulpurcaz26y74slp3lfayyeu3n547esianwwpf6ha55e/";
    }

    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Withdraws the balance of the contract to a specified payee
    /// @dev Can only be called by the contract owner; uses a nonReentrant modifier for security
    /// @param payee The address of the payee to transfer the balance to
    function withdrawPayments(address payable payee) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) revert WithdrawTransferFailed();
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
