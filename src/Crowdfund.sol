// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Crowdfund
/// @notice A crowd funding smart contract that allows users to create and participate in crowdfunding campaigns.
contract Crowdfund {
    // Types

    struct Campaign {
        bool isInitialized;
        bool isPaidOut;
        string title;
        string description;
        address benefactor;
        uint goal;
        uint deadline;
        uint amountRaised;
    }

    // State variables
    mapping(uint => Campaign) campaigns;
    mapping(address => uint[]) userCampaigns;
    uint numCampaigns;
    uint totalFunding;

    // Events
    event CampaignCreated(address indexed creator, uint indexed campaignId);
    event CampaignEnded(
        address indexed creator,
        uint indexed campaignId,
        uint indexed amountRaised
    );
    event DonationReceived(
        uint indexed campaignId,
        address indexed donator,
        uint indexed amount
    );

    // Errors
    error Crowdfund_InvalidCampaign(uint id);
    error Crowdfund_CannotDonateZero();
    error Crowdfund_CampaignInactive();
    error Crowdfund_CampaignNotEnded(uint deadline);
    error Crowdfund_NoFundsRaised();
    error Crowdfund_PayoutFailed();

    // Modifiers

    // Functions

    constructor() {}

    /// @notice Creates a new crowdfunding campaign.
    /// @param _title The title of the campaign.
    /// @param _description The description of the campaign.
    /// @param _goal The funding goal of the campaign.
    /// @param _deadline The deadline for the campaign.
    /// @return campaignId The ID of the created campaign.
    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint _goal,
        uint _deadline
    ) public returns (uint campaignId) {
        Campaign memory newCampaign = Campaign({
            isInitialized: true,
            isPaidOut: false,
            title: _title,
            description: _description,
            benefactor: msg.sender,
            goal: _goal,
            deadline: block.timestamp + _deadline,
            amountRaised: 0
        });

        campaignId = numCampaigns;
        uint[] storage _userCampaigns = userCampaigns[msg.sender];

        numCampaigns += 1;

        campaigns[campaignId] = newCampaign;
        _userCampaigns.push(campaignId);

        emit CampaignCreated(msg.sender, campaignId);
    }

    /// @notice Allows a user to donate to a specific campaign.
    /// @param campaignId The ID of the campaign to donate to.
    function donateToCampaign(uint campaignId) public payable {
        if (msg.value == 0) revert Crowdfund_CannotDonateZero();
        Campaign storage campaign = campaigns[campaignId];
        if (!campaign.isInitialized)
            revert Crowdfund_InvalidCampaign(campaignId);
        if (block.timestamp > campaign.deadline)
            revert Crowdfund_CampaignInactive();

        totalFunding += msg.value;
        campaign.amountRaised += msg.value;

        emit DonationReceived(campaignId, msg.sender, msg.value);
    }

    /// @notice Ends a specific campaign and pays out the funds to the benefactor.
    /// @param campaignId The ID of the campaign to end.
    function endCampaign(uint campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        if (block.timestamp < campaign.deadline)
            revert Crowdfund_CampaignNotEnded(campaign.deadline);

        if (campaign.isPaidOut) revert Crowdfund_CampaignInactive();

        if (campaign.amountRaised == 0) revert Crowdfund_NoFundsRaised();

        campaign.isPaidOut = true;
        totalFunding -= campaign.amountRaised;

        (bool success, ) = payable(campaign.benefactor).call{
            value: campaign.amountRaised
        }("");

        if (!success) revert Crowdfund_PayoutFailed();

        emit CampaignEnded(
            campaign.benefactor,
            campaignId,
            campaign.amountRaised
        );
    }

    /// @notice Gets the total number of campaigns.
    /// @return The total number of campaigns.
    function getTotalCampaigns() external view returns (uint) {
        return numCampaigns;
    }

    /// @notice Gets the total funding amount.
    /// @return The total funding amount.
    function getTotalFunding() external view returns (uint) {
        return totalFunding;
    }

    /// @notice Gets the campaigns created by a specific user.
    /// @param user The address of the user.
    /// @return The array of campaign IDs created by the user.
    function getUserCampaigns(
        address user
    ) external view returns (uint[] memory) {
        return userCampaigns[user];
    }

    /// @notice Gets the campaign details by ID.
    /// @param campaignId The ID of the campaign.
    /// @return The campaign details.
    function getCampaignById(
        uint campaignId
    ) external view returns (Campaign memory) {
        return campaigns[campaignId];
    }
}
