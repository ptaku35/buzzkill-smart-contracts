// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HiveVaultV1Basic} from "../src/Hive/HiveVaultV1Basic.sol";

contract DeployHiveVault is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address buzzkill = 0x1a8987e126B572c3De795180A86fCAb643543f92;
    address honey = 0x9BfbBd6b4d523D832c5D5cB0bE7C33EeD91787f1;
    uint256 initialRewards = 10;

    function run() external  {
        vm.startBroadcast(deployerPrivateKey);

        HiveVaultV1Basic hive = new HiveVaultV1Basic(
            msg.sender,
            buzzkill,
            honey,
            initialRewards
        );
        vm.stopBroadcast();

        console.log("HiveVault Address: ", address(hive));
    }
}