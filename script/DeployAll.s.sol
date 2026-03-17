// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HsToken} from "../src/HsToken.sol";
import {HsNft} from "../src/HsNft.sol";

contract DeployAll is Script {
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    function run() external returns (HsToken, HsNft) {
        string memory baseUri = vm.envString("NFT_BASE_URI");

        vm.startBroadcast();
        HsToken hsToken = new HsToken(INITIAL_SUPPLY);
        HsNft hsNft = new HsNft(address(hsToken), baseUri);
        vm.stopBroadcast();

        console.log("-----------------------------------------");
        console.log("HsToken deployed at:", address(hsToken));
        console.log("HsNft deployed at:  ", address(hsNft));
        console.log("Base URI set to:    ", baseUri);
        console.log("-----------------------------------------");

        return (hsToken, hsNft);
    }
}
