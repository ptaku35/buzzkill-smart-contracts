// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC725} from "@vrc725/contracts/VRC725.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {VRC725Enumerable} from "@vrc725/contracts/extensions/VRC725Enumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Buzzkill is VRC725, VRC725Enumerable, ReentrancyGuard, Pausable {
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
    uint256 public constant MINT_PRICE = 0.007 ether; //? Not sure about having this a hard coded constant

    constructor() {
        __VRC725_init("Buzzkill", "BZK", msg.sender);
    }

    ////////////////////////
    /// FUNCTIONS
    ////////////////////////
    function mintTo(address to) public payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.value != MINT_PRICE) {
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
     * @dev Required override from VRC725.
     * *! Need to appropriately implement function
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
