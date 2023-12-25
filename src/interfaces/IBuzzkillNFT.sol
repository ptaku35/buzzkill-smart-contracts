// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IBuzzkillNFT {

    /// @notice Mint a new token to a specified address
    /// @param to The address to which the token will be minted
    /// @return The token ID of the minted token
    function mintTo(address to) external payable returns (uint256);

    /// @notice Burn a token with a specified token ID
    /// @param tokenId The ID of the token to be burned
    function burn(uint256 tokenId) external;

    /// @notice Withdraw the contract's balance to a specified payee
    /// @param payee The address to which the balance will be sent
    function withdrawPayments(address payable payee) external;

    /// @notice Update the mint price of the NFT
    /// @param newMintPrice The new mint price to be set
    /// @return A boolean indicating the success of the function
    function UpdateMintPrice(uint256 newMintPrice) external returns (bool);

    /// @notice Pause the contract, disabling certain functions
    function pause() external;

    /// @notice Unpause the contract, re-enabling the disabled functions
    function unpause() external;

    /// @notice Check if a given interface ID is supported by the contract
    /// @param interfaceId The interface ID to check for support
    /// @return True if the interface is supported, false otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @notice Get the owner of a specific token
    /// @param tokenId The token ID to query for its owner
    /// @return The address of the owner of the specified token
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Transfer NFT. Function from VRC725
    /// @param from address from
    /// @param to address to
    /// @param tokenId NFT to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
