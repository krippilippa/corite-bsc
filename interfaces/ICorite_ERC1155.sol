// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICorite_ERC1155 {
    function createCampaign(
        address _owner,
        uint256 _supplyCap,
        uint256 _toBackersCap
    ) external returns (uint256);

    function closeCampaign(uint256 _campaign) external;

    function mintCampaignShares(
        uint256 _campaign,
        uint256 _amount,
        address _to
    ) external;

    function setCampaignCancelled(uint256 _campaign, bool _cancelled) external;

    function burnToken(
        uint256 _fullTokenId,
        uint256 _amount,
        address _from
    ) external;
}
