// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {BuzzkillNFT} from "src/NFT/BuzzkillNFT.sol";

contract DeployBuzzkill is Script {
    /// @notice The main script entrypoint
    /// @return buzzkill The deployed contract
    function run() external returns (BuzzkillNFT buzzkill) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        buzzkill = new BuzzkillNFT(1 ether);
        vm.stopBroadcast();

        console.log("NFT Address: ", address(buzzkill));
    }
}
