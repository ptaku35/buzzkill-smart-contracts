// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC25} from "@vrc25/contracts/VRC25.sol";
import {VRC25Permit} from "@vrc25/contracts/VRC25Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Controllable} from "../utils/Controllable.sol";

contract Honey is VRC25, VRC25Permit, Controllable, ReentrancyGuard {
    error ExceededMaxSupply();

    uint256 public constant MAX_SUPPLY = 10e9 * 10e18;

    constructor() VRC25("HONEY", "HNY", 18) {}

    /// @notice Mint new tokens to `to` with amount of `amount`.
    function mintTo(address to, uint256 amount) external onlyController nonReentrant {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert ExceededMaxSupply();
        }
        super._mint(to, amount);
    }

    /// @notice Burn tokens from `from` with amount of `value`.
    function burn(address from, uint256 value) external onlyController {
        super._burn(from, value);
    }

    /// @notice Add or edit contract controllers.
    /// @param addr An address to be added/edited.
    /// @param state New controller state of address.
    function setControllers(address addr, bool state) external onlyOwner {
        super._setController(addr, state);
    }

    /// @dev Required override function for VRC25
    /// @notice Calculate fee required for action related to this token
    /// @param value Amount of fee
    function _estimateFee(uint256 value) internal view override returns (uint256) {
        return value + minFee();
    }
}


