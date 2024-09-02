// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IHoney {

    /// @notice Mint new tokens to `to` with amount of `amount`.
    function mintTo(address to, uint256 amount) external;

    /// @notice Burn tokens from `from` with amount of `value`.
    function burn(address from, uint256 value) external;

    /// @notice Add or edit contract controllers.
    /// @param addr An address to be added/edited.
    /// @param state New controller state of address.
    function setControllers(address addr, bool state) external;

    // Override functions from VRC25
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
