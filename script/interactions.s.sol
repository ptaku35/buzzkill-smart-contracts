// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {BuzzkillNFT} from "src/NFT/BuzzkillNFT.sol";


contract MintNFT is Script {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    BuzzkillNFT nft;
    address nftAddress = 0x1a8987e126B572c3De795180A86fCAb643543f92;

    function run() payable external {
        vm.startBroadcast(deployerPrivateKey);
        
        nft = BuzzkillNFT(nftAddress);
        nft.mintTo{value: msg.value}(0x62EbD0dd2Ef68a8EcF68CF0688f8e0430A7C61F0);
        
        vm.stopBroadcast(); 
    }


}