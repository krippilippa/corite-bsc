// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "../libraries/MarketLib.sol";

contract MarketState is AccessControl {
    bytes32 public constant HANDLER = keccak256("HANDLER");

    mapping(address => bool) public validTokens;
    mapping(address => MarketLib.ValidContract) public validContracts;
    
    mapping(address => MarketLib.Listing[]) public listings;
    mapping(address => mapping(uint=> uint)) public listingIndex;

    mapping(address => mapping(uint => MarketLib.CampaignListing[])) public campaignListings;
    mapping(address => mapping(uint => mapping(address => uint))) public campaignListingIndex;

    constructor(address _default_admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
    }

    function addListing(address _contract, address _owner, uint _tokenId, address _currency, uint _price) external onlyRole(HANDLER) {
        _removeListing(_contract, _tokenId);
        require(IERC721(_contract).ownerOf(_tokenId) == _owner, "Invalid token owner");
        listingIndex[_contract][_tokenId] = listings[_contract].length;
        listings[_contract].push(MarketLib.Listing({tokenId: _tokenId, owner: _owner, currency: _currency, price: _price}));
    }

    function addCampaignListing(address _contract, uint _campaignId, address _owner, uint _amount, address _currency, uint _unitPrice) external onlyRole(HANDLER) {
        _removeCampaignListing(_contract, _campaignId, _owner);
        require(IERC1155(_contract).balanceOf(_owner, _campaignId) >= _amount, "Invalid token balance");
        campaignListingIndex[_contract][_campaignId][_owner] = campaignListings[_contract][_campaignId].length;
        campaignListings[_contract][_campaignId].push(MarketLib.CampaignListing({owner: _owner, currency: _currency, unitPrice: _unitPrice, amount: _amount}));
    }

    function removeListing(address _contract, uint _tokenId) external onlyRole(HANDLER) {
       _removeListing(_contract, _tokenId);
    }

    function removeCampaignListing(address _contract, uint _campaignId, address _owner) external onlyRole(HANDLER) {
       _removeCampaignListing(_contract, _campaignId, _owner);
    }

    function _removeListing(address _contract, uint _tokenId) internal {
        uint index = listingIndex[_contract][_tokenId];
        if(listings[_contract].length > 0 && listings[_contract][index].tokenId == _tokenId) {
            MarketLib.Listing memory lastListing = listings[_contract][listings[_contract].length - 1];
            listings[_contract][index] = lastListing;
            listings[_contract].pop();
            listingIndex[_contract][lastListing.tokenId] = index;
            delete listingIndex[_contract][_tokenId];
        }
    }

     function _removeCampaignListing(address _contract, uint _campaignId, address _owner) internal {
        uint index = campaignListingIndex[_contract][_campaignId][_owner];
        if(campaignListings[_contract][_campaignId].length > 0 && campaignListings[_contract][_campaignId][index].owner == _owner) {
            MarketLib.CampaignListing memory lastListing = campaignListings[_contract][_campaignId][campaignListings[_contract][_campaignId].length - 1];
            campaignListings[_contract][_campaignId][index] = lastListing;
            campaignListings[_contract][_campaignId].pop();
            campaignListingIndex[_contract][_campaignId][lastListing.owner] = index;
            delete campaignListingIndex[_contract][_campaignId][_owner];
        }
    }

    function setValidToken(address _token, bool _valid) external onlyRole(HANDLER) {
        validTokens[_token] = _valid;
    }

    function addValidContract(address _contract, address _feeAccount, uint _feeRate) external onlyRole(HANDLER) {
        validContracts[_contract] = MarketLib.ValidContract({feeRate: _feeRate, feeAccount: _feeAccount, valid: true});
    }

    function setValidContract(address _contract, bool _valid) external onlyRole(HANDLER) {
        validContracts[_contract].valid = _valid;
    }

    function isValidContract(address _contract) external view returns (bool) {
        return validContracts[_contract].valid;
    }

    function getListing(address _contract, uint _tokenId) external view returns (MarketLib.Listing memory) {
        require(listings[_contract].length > 0, "Token is not listed");
        uint index = listingIndex[_contract][_tokenId];
        if(index == 0) {
            require(listings[_contract][index].tokenId == _tokenId, "Token is not listed");
        }
        return listings[_contract][index];
    }

    function getActiveListings(address _contract, uint _start, uint _end) external view returns (MarketLib.Listing[] memory) {
        require(_end >= _start || _end == 0, "Invalid end index");
        if(_start == 0 && _end == 0) {
            return listings[_contract];
        }
        if(_end > listings[_contract].length || _end == 0) {
            _end = listings[_contract].length;
        }
        MarketLib.Listing[] memory a = new MarketLib.Listing[](_end - _start);
        for(uint i = 0; i < _end - _start; i++){
            a[i] = listings[_contract][i + _start];
        }
        return a;
    }

    function getListingCount(address _contract) external view returns (uint) {
        return listings[_contract].length;
    }

    function getCampaignListing(address _contract, uint _campaignId, address _owner) external view returns (MarketLib.CampaignListing memory) {
        require(campaignListings[_contract][_campaignId].length > 0, "Address does not have a listing in this campaign");
        uint index = campaignListingIndex[_contract][_campaignId][_owner];
        if(index == 0) {
            require(campaignListings[_contract][_campaignId][index].owner == _owner, "Address does not have a listing in this campaign");
        }
        return campaignListings[_contract][_campaignId][index];
    }

    function getActiveCampaignListings(address _contract, uint _campaignId, uint _start, uint _end) external view returns (MarketLib.CampaignListing[] memory) {
        require(_end >= _start || _end == 0, "Invalid end index");
        if(_start == 0 && _end == 0) {
            return campaignListings[_contract][_campaignId];
        }
        if(_end > campaignListings[_contract][_campaignId].length || _end == 0) {
            _end = campaignListings[_contract][_campaignId].length;
        }
        MarketLib.CampaignListing[] memory a = new MarketLib.CampaignListing[](_end - _start);
        for(uint i = 0; i < _end - _start; i++){
            a[i] = campaignListings[_contract][_campaignId][i + _start];
        }
        return a;
    }

    function getCampaignListingCount(address _contract, uint _campaignId) external view returns (uint) {
        return campaignListings[_contract][_campaignId].length;
    }
}