// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Honey} from "../src/RewardToken/Honey.sol";

contract DeployHoney is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        Honey honey = new Honey();
        vm.stopBroadcast();
        console.log("Honey Address: ", address(honey));
    }
}