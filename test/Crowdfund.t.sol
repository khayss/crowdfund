// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Crowdfund} from "../src/Crowdfund.sol";
import {Test, console} from "forge-std/Test.sol";

contract CrowdfundTest is Test {
    Crowdfund public crowdfund;
    address fakeUser = vm.addr(1);

    function setUp() public {
        crowdfund = new Crowdfund();
    }

    function test_IsInitializedCorrectly() public view {
        assertEq(crowdfund.getTotalCampaigns(), 0);
        assertEq(crowdfund.getTotalFunding(), 0);
        assertEq(crowdfund.getUserCampaigns(fakeUser).length, 0);
    }

    function test_CanCreateCampaign() public {
        vm.deal(fakeUser, 1 ether);

        string memory title = "Test Campaign";
        string memory description = "This is a test campaign.";
        uint goal = 1 ether;
        uint deadline = 1 minutes;

        vm.prank(fakeUser);
        uint campaignId = crowdfund.createCampaign(
            title,
            description,
            goal,
            deadline
        );
        

        assertEq(campaignId, 0);
        assertEq(crowdfund.getTotalCampaigns(), 1);
        assertEq(crowdfund.getTotalFunding(), 0);
        // assertEq(crowdfund.getUserCampaigns(fakeUser).length, 1);
        // console.log(crowdfund.getUserCampaigns(fakeUser));
    }
}
