// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HiveVaultV1} from "../src/Hive/HiveVaultV1.sol";

contract DeployHiveVault is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address buzzkill = 0x1a8987e126B572c3De795180A86fCAb643543f92;
    address honey = 0x9BfbBd6b4d523D832c5D5cB0bE7C33EeD91787f1;
    address beeSkills = 0x36bc480435F4C55f59CF49d6D4D9B48ca63bDF36;

    function run() external  {
        vm.startBroadcast(deployerPrivateKey);

        HiveVaultV1 hive = new HiveVaultV1(
            msg.sender,     // owner
            buzzkill,       // staking NFT
            honey,          // reward token
            beeSkills,      // traits contract
            10,             // rate
            3,              // max queens per hive
            20,             // max workers per hive
            1 days,         // epoch time
            0               // lockup duration
        );
        vm.stopBroadcast();

        console.log("HiveVault Address: ", address(hive));
    }
}