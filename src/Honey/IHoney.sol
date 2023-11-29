// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IVRC25} from "@vrc25/contracts/interfaces/IVRC25.sol";

interface IHoney is IVRC25 {
    /*
        Honey is used for:
            - Buying upgrades
            - Fees for staking and unstaking NFT's
            - Cost for raiding
    */

    function mintTo(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;
}
