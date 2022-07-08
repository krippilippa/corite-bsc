// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/MarketLib.sol";

interface IMarketState {
    function validTokens(address _token) external returns (bool);

    function validContracts(address _contract) external returns (MarketLib.ValidContract memory);

    function addListing(address _contract, address _owner, uint _tokenId, address _currency, uint _price) external;

    function removeListing(address _contract, uint _tokenId) external;

    function setValidToken(address _token, bool _valid) external;

    function addValidContract(address _contract, address _feeAccount, uint _feeRate) external;

    function setValidContract(address _contract, bool _valid) external;

    function isValidContract(address _contract) external view returns (bool);

    function getListing(address _contract, uint _tokenId) external view returns (MarketLib.Listing memory);

    function getActiveListings(address _contract, uint _start, uint _end) external view returns (MarketLib.Listing[] memory);

    function addCampaignListing(address _contract, uint _campaignId, address _owner, uint _amount, address _currency, uint _unitPrice) external;

    function removeCampaignListing(address _contract, uint _campaignId, address _owner) external;

    function getCampaignListing(address _contract, uint _campaignId, address _owner) external view returns (MarketLib.CampaignListing memory);

    function getActiveCampaignListings(address _contract, uint _campaignId) external view returns (MarketLib.CampaignListing[] memory);

    function getListingCount(address _contract) external view returns (uint);

    function getCampaignListingCount(address _contract, uint _campaignId) external view returns (uint);
}