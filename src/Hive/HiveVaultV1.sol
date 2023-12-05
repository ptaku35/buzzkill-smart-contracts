// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Honey} from "../Honey/Honey.sol";
import {BuzzkillNFT} from "../NFT/BuzzkillNFT.sol";
import {TraitsState} from "../traits/TraitsState.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Hive Vault
contract HiveVaultV1 is Ownable, Pausable, ReentrancyGuard {

    /* -------------------------------------------------------------------------- */
    /*  State Variables                                                           */
    /* -------------------------------------------------------------------------- */




    /// @notice Staking token contract address
    BuzzkillNFT buzzkillNFT;

    /// @notice Rewards token contract address
    Honey honey;














    constructor(address owner) Ownable(owner) {

        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*  Logic Functions                                                           */
    /* -------------------------------------------------------------------------- */




















    /* -------------------------------------------------------------------------- */
    /*  Owner Functions                                                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}
