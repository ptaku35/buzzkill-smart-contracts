// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sample {
    uint256 public number;

    constructor() {
        number = 0;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }
}
