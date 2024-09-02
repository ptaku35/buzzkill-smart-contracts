// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {BeeSkills} from "src/traits/BeeSkills.sol";

contract DeployBeeSkills is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address hiveVault = 0xb4FB355b0A0A899E3146bf59B0AfCD162A7c3AbC;
    address buzzkill = 0x1a8987e126B572c3De795180A86fCAb643543f92;
    address honey = 0x9BfbBd6b4d523D832c5D5cB0bE7C33EeD91787f1;

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        BeeSkills beeSkills = new BeeSkills(
            payable(msg.sender),
            hiveVault,
            buzzkill,
            honey
        );

        vm.stopBroadcast();
        console.log("Contract Address: ", address(beeSkills));
    }
}
