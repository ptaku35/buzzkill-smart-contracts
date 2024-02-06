// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HiveVaultV1} from "../src/Vault/HiveVaultV1.sol";
import {HiveVaultV1Basic} from "../src/Vault/HiveVaultV1Basic.sol";

contract DeployHiveVaultV1 is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address buzzkill = 0x1a8987e126B572c3De795180A86fCAb643543f92; //! NO MORE HARDING CODING! GET FROM JSON
    address honey = 0x9f2ae804Ae4A496A4F71ae16a509A67a151Ab787;
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

contract DeployHiveVaultV1Basic is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address buzzkill = 0x1a8987e126B572c3De795180A86fCAb643543f92; //! NO MORE HARDING CODING! GET FROM JSON
    address honey = 0x9f2ae804Ae4A496A4F71ae16a509A67a151Ab787;//! NO MORE HARDING CODING! GET FROM JSON

    function run() external  {
        vm.startBroadcast(deployerPrivateKey);

        HiveVaultV1Basic hive = new HiveVaultV1Basic(
            msg.sender,     // owner
            buzzkill,       // staking NFT
            honey,          // reward token
            10             // rate
        );
        vm.stopBroadcast();

        console.log("HiveVault Address: ", address(hive));
    }
}