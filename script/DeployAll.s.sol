// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HsToken} from "../src/HsToken.sol";
import {HsNft} from "../src/HsNft.sol";

contract DeployAll is Script {
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    // 임시주소 추후 ipfs에 올린 메타데이터 폴더 주소로 변경
    string public constant BASE_URI = "ipfs://QmYourFolderCIDhere/";

    function run() external returns (HsToken, HsNft) {
        vm.startBroadcast();
        HsToken hsToken = new HsToken(INITIAL_SUPPLY);
        HsNft hsNft = new HsNft(address(hsToken), BASE_URI);
        vm.stopBroadcast();

        console.log("-----------------------------------------");
        console.log("HsToken deployed at:", address(hsToken));
        console.log("HsNft deployed at:  ", address(hsNft));
        console.log("-----------------------------------------");

        return (hsToken, hsNft);
    }
}
