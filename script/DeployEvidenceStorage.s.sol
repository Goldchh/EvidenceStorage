// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import "../src/EvidenceStorage.sol";

contract DeployEvidenceStorage is Script {

    function run() external returns (EvidenceStorage){
        vm.startBroadcast();
        EvidenceStorage evidenceStorage = new EvidenceStorage(msg.sender);
        vm.stopBroadcast();
        return evidenceStorage;
    }
    
}