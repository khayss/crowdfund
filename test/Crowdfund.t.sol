// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Crowdfund} from "../src/Crowdfund.sol";
import {Test, console} from "forge-std/Test.sol";

contract CrowdfundTest is Test {
    Crowdfund public crowdfund;
    address fakeUser = vm.addr(1);

    function setUp() public {
        vm.deal(fakeUser, 1 ether);
        crowdfund = new Crowdfund();
    }

    function newCampaign() public returns (uint campaignId) {
        string memory title = "Test Campaign";
        string memory description = "This is a test campaign.";
        uint goal = 1 ether;
        uint deadline = 1 minutes;

        vm.prank(fakeUser);
        campaignId = crowdfund.createCampaign(
            title,
            description,
            goal,
            deadline
        );
    }

    function test_IsInitializedCorrectly() public view {
        assertEq(crowdfund.getTotalCampaigns(), 0);
        assertEq(crowdfund.getTotalFunding(), 0);
        assertEq(crowdfund.getUserCampaigns(fakeUser).length, 0);
    }

    function test_CanCreateCampaign() public {
        uint campaignId = newCampaign();
        uint[] memory userCampaigns = crowdfund.getUserCampaigns(fakeUser);

        assertEq(campaignId, 0);
        assertEq(crowdfund.getTotalCampaigns(), 1);
        assertEq(crowdfund.getTotalFunding(), 0);
        assertEq(userCampaigns.length, 1);
    }

    function test_CanDonateToCampaign() public {
        uint campaignId = newCampaign();
        uint amount = 10 ether;
        uint amountToDonate = 1 ether;

        address fakeDonor1 = vm.addr(2);
        address fakeDonor2 = vm.addr(3);

        vm.deal(fakeDonor1, amount);
        vm.deal(fakeDonor2, amount);

        vm.prank(fakeDonor1);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        vm.prank(fakeDonor2);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        assertEq(crowdfund.getTotalFunding(), amountToDonate * 2);
        assertEq(
            crowdfund.getCampaignAmountRaised(campaignId),
            amountToDonate * 2
        );
    }

    function test_CannotDonateZero() public {
        uint amount = 10 ether;
        address fakeDonor = vm.addr(2);
        vm.deal(fakeDonor, amount);
        uint campaignId = newCampaign();

        vm.expectRevert(Crowdfund.Crowdfund_CannotDonateZero.selector);
        vm.prank(fakeDonor);
        crowdfund.donateToCampaign{value: 0}(campaignId);
    }

    function test_CannotDonateToInvalidCampaign() public {
        uint campaignId = 1;
        address fakeDonor = vm.addr(2);
        uint amount = 10 ether;
        uint amountToDonate = 1 ether;

        vm.deal(fakeDonor, amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                Crowdfund.Crowdfund_InvalidCampaign.selector,
                campaignId
            )
        );
        vm.prank(fakeDonor);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);
    }

    function test_BenefactorCanWithdrawWhenCampaignEnd() public {
        uint campaignId = newCampaign();
        uint amount = 10 ether;
        uint amountToDonate = 1 ether;

        address fakeDonor1 = vm.addr(2);
        address fakeDonor2 = vm.addr(3);

        vm.deal(fakeDonor1, amount);
        vm.deal(fakeDonor2, amount);

        vm.prank(fakeDonor1);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        vm.prank(fakeDonor2);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        vm.warp(block.timestamp + 2 minutes);
        vm.roll(block.number + 4);

        uint userBalanceBefore = fakeUser.balance;

        vm.prank(fakeUser);
        crowdfund.endCampaign(campaignId);

        assertEq(crowdfund.getTotalFunding(), 0);
        assertEq(fakeUser.balance, userBalanceBefore + amountToDonate * 2);
    }

    function test_CannotEndCampaignBeforeDeadline() public {
        uint campaignId = newCampaign();
        uint amount = 10 ether;
        uint amountToDonate = 1 ether;

        address fakeDonor1 = vm.addr(2);
        address fakeDonor2 = vm.addr(3);

        vm.deal(fakeDonor1, amount);
        vm.deal(fakeDonor2, amount);

        vm.prank(fakeDonor1);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        vm.prank(fakeDonor2);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        vm.expectRevert(
            abi.encodeWithSelector(
                Crowdfund.Crowdfund_CampaignNotEnded.selector,
                block.timestamp + 60
            )
        );
        vm.prank(fakeUser);
        crowdfund.endCampaign(campaignId);
    }

    function test_CannotDonateAfterCampaignEnd() public {
        uint campaignId = newCampaign();
        uint amount = 10 ether;
        uint amountToDonate = 1 ether;

        address fakeDonor1 = vm.addr(2);
        address fakeDonor2 = vm.addr(3);

        vm.deal(fakeDonor1, amount);
        vm.deal(fakeDonor2, amount);

        vm.prank(fakeDonor1);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);

        vm.warp(block.timestamp + 2 minutes);
        vm.roll(block.number + 4);

        vm.expectRevert(
            abi.encodeWithSelector(
                Crowdfund.Crowdfund_CampaignInactive.selector
            )
        );
        vm.prank(fakeDonor2);
        crowdfund.donateToCampaign{value: amountToDonate}(campaignId);
    }
}
