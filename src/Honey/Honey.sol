// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VRC25} from "@vrc25/contracts/VRC25.sol";
import {VRC25Permit} from "@vrc25/contracts/VRC25Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Honey is VRC25, VRC25Permit, ReentrancyGuard {
    error ExceededMaxSupply();

    uint256 public constant MAX_SUPPLY = 10e9;

    constructor() VRC25("HONEY", "HNY", 18) {}

    /**
     * @notice Issues `amount` tokens to the designated `address`.
     */
    function mintTo(address _to, uint256 _amount) external onlyOwner nonReentrant returns (bool) {
        //! Need to guard against overflow if not using the latest compiler; will need SafeMath
        if (totalSupply() + _amount > MAX_SUPPLY) {
            revert ExceededMaxSupply();
        }

        _mint(_to, _amount);
        return true;
    }

    /**
     * @dev Required override function for VRC25
     * @notice Calculate fee required for action related to this token
     * @param value Amount of fee
     */
    function _estimateFee(uint256 value) internal view override returns (uint256) {
        return value + minFee();
    }
}
