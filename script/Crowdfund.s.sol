// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Crowdfund} from "../src/Crowdfund.sol";
import {Script, console} from "forge-std/Script.sol";

contract CrowdfundDeploy is Script {
    function run() external returns (Crowdfund) {
        vm.startBroadcast();

        Crowdfund crowdfund = new Crowdfund();

        vm.stopBroadcast();

        return crowdfund;
    }
}
