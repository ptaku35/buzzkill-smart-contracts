// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";

import {Buzzkill} from "src/Buzzkill.sol";

import {Sample} from "../src/Sample.sol";

contract DeployBuzzkill is Script {
    // string public constant TOKENURI =
    //     "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    /// @notice The main script entrypoint
    /// @return buzzkill The deployed contract
    function run() external returns (Buzzkill buzzkill) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        buzzkill = new Buzzkill();
        vm.stopBroadcast();
    }
}

contract DeploySample is Script {
    function run() external returns (Sample sample) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        sample = new Sample();
        vm.stopBroadcast;
    }
}
