// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC725} from "@vrc725/contracts/VRC725.sol";


contract Buzzkill is VRC725 {
    uint256 private _nextTokenId;

    // Mapping from tokenId's to token URIs
    mapping(uint256 tokenId => string) private tokenIdToTokenURI;

    event MetadataUpdate(uint256);

    constructor() {
        __VRC725_init("Buzzkill", "BZK", msg.sender);
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = tokenIdToTokenURI[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert("Nonexistent token");
        }
        return owner;
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        tokenIdToTokenURI[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }
}
