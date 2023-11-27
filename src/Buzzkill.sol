// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC725} from "@vrc725/contracts/VRC725.sol";

error MintPriceNotPaid();
error MaxSupply();
error WithdrawTransfer();

contract Buzzkill is VRC725 {

    uint256 private currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public constant MINT_PRICE = 0.0073 ether;

    constructor() {
        __VRC725_init("Buzzkill", "BZK", msg.sender);
    }

    function mintTo(address to) public payable onlyOwner {
        if (msg.value != MINT_PRICE) {
            revert MintPriceNotPaid();
        }
        uint256 newTokenId = ++currentTokenId;

        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _safeMint(to, newTokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://<SOME HASH HERE>/";
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    /**
     * @dev Required override from VRC725.
     * *! Need to appropriately implement function
     */
    function _estimateFee(
        uint256 value
    ) internal pure override returns (uint256) {
        // Need to implement this function to prevent "abstract" error
        // This is just an example implementation of a fixed fee of 1% of the transaction value
        uint256 percentageFee = (value * 1) / 100;

        // Ensure the fee is at least 1 (you can adjust this based on your requirements)
        return percentageFee > 1 ? percentageFee : 1;
    }
}
