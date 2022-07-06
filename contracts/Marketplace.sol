// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../interfaces/ISingleApproveProxy.sol";
import "../interfaces/IMarketState.sol";
import "../libraries/MarketLib.sol";

contract Marketplace is AccessControl, Pausable {
bytes32 public constant MARKET_ADMIN = keccak256("MARKET_ADMIN");

    ISingleApproveProxy public proxy;
    IMarketState public marketState;

    uint public taxRate;
    address public taxAccount;

    event AddListing(address indexed _contract, uint indexed tokenId, address indexed owner, address currency, uint price);
    event RemoveListing(address indexed _contract, uint indexed tokenId);
    event BoughtNFT(address indexed _contract, uint indexed tokenId, address seller, address indexed buyer, address currency, uint price);
    event AddCampaignListing(address indexed _contract, uint indexed campaignId, address indexed owner, uint amount, address currency, uint unitPrice);
    event RemoveCampaignListing(address indexed _contract, uint indexed campaignId, address owner);
    event BoughtCampaignShares(address indexed _contract, uint indexed campaignId, address seller, address indexed buyer, uint amount, address currency, uint unitPrice);

    constructor(ISingleApproveProxy _proxy, IMarketState _marketState, address _default_admin) {
        proxy = _proxy;
        marketState = _marketState;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
    }

    function addListing(address _contract, uint _tokenId, address _currency, uint _price) external whenNotPaused {
        require(marketState.isValidContract(_contract), "Invalid NFT contract");
        require(_price > 0, "Listing price can not be 0");
        require(marketState.validTokens(_currency), "Invalid currency token");
        
        marketState.addListing(_contract, msg.sender, _tokenId, _currency, _price);
        emit AddListing(_contract, _tokenId, msg.sender, _currency, _price);
    }

    function addCampaignListing(address _contract, uint _campaignId, uint _amount, address _currency, uint _unitPrice) external whenNotPaused {
        require(marketState.isValidContract(_contract), "Invalid NFT contract");
        require(_unitPrice > 0, "Unit price can not be 0");
        require(marketState.validTokens(_currency), "Invalid currency token");
        
        marketState.addCampaignListing(_contract, _campaignId, msg.sender, _amount, _currency, _unitPrice);
        emit AddCampaignListing(_contract, _campaignId, msg.sender, _amount, _currency, _unitPrice);
    }

    function removeListing(address _contract, uint _tokenId) external whenNotPaused {
        require(marketState.getListing(_contract, _tokenId).owner == msg.sender || hasRole(MARKET_ADMIN, msg.sender), "Invalid token owner");
        marketState.removeListing(_contract, _tokenId);
        emit RemoveListing(_contract, _tokenId);
    }

    function removeCampaignListing(address _contract, uint _tokenId, address _owner) external whenNotPaused {
        require(marketState.getCampaignListing(_contract, _tokenId, _owner).owner == msg.sender || hasRole(MARKET_ADMIN, msg.sender), "Invalid token owner");
        marketState.removeCampaignListing(_contract, _tokenId, _owner);
        emit RemoveCampaignListing(_contract, _tokenId, _owner);
    }

    function buyNFT(address _contract, uint _tokenId, address _currency, uint _price) external whenNotPaused {
        MarketLib.Listing memory listing = marketState.getListing(_contract, _tokenId);
        require(listing.currency == _currency && listing.price == _price, "Price mis-match");

        MarketLib.ValidContract memory tokenContract = marketState.validContracts(_contract);
        _transferValue(_currency, _price,  tokenContract.feeAccount, tokenContract.feeRate, listing.owner);
        proxy.transferERC721(_contract, listing.owner, msg.sender, _tokenId);

        marketState.removeListing(_contract, _tokenId);
        emit BoughtNFT(_contract, _tokenId, listing.owner, msg.sender, _currency, _price);
    }

    function buyCampaignShares(address _contract, uint _campaignId, address _seller, uint _amount, address _currency, uint _unitPrice) external whenNotPaused {
        MarketLib.CampaignListing memory listing = marketState.getCampaignListing(_contract, _campaignId, _seller);
        require(listing.amount == _amount && listing.currency == _currency && listing.unitPrice == _unitPrice, "Price mis-match");

        MarketLib.ValidContract memory tokenContract = marketState.validContracts(_contract);
        _transferValue(_currency, _unitPrice * _amount,  tokenContract.feeAccount, tokenContract.feeRate, _seller);
        proxy.transferERC1155(_contract, listing.owner, msg.sender, _campaignId, _amount);

        marketState.removeCampaignListing(_contract, _campaignId, _seller);
        emit BoughtCampaignShares(_contract, _campaignId, listing.owner, msg.sender, _amount, _currency, _unitPrice);
    }
    
    function _transferValue( address _currency, uint _price, address _feeAccount, uint _feeRate, address _owner) internal {
        uint amountAfterTax = _price;
        if(taxRate != 0) {
            uint tax = (_price * taxRate) / 100;
            amountAfterTax -= tax;
            proxy.transferERC20(_currency, msg.sender, taxAccount, tax);
        }
        if(_feeRate != 0) {
            uint fee = (_price * _feeRate) / 100;
            amountAfterTax -= fee;
            proxy.transferERC20(_currency, msg.sender, _feeAccount, fee);
        }
        proxy.transferERC20(_currency, msg.sender, _owner, amountAfterTax);
    }

    function setValidToken(address _token, bool _valid) external onlyRole(MARKET_ADMIN) {
        marketState.setValidToken(_token, _valid);
    }

    function addValidContract(address _contract, address _feeAccount, uint _feeRate) external onlyRole(MARKET_ADMIN) {
        marketState.addValidContract(_contract, _feeAccount, _feeRate);
    }

    function setValidContract(address _contract, bool _valid) external onlyRole(MARKET_ADMIN) {
        marketState.setValidContract(_contract, _valid);
    }

    function setTaxRate(uint _taxRate) external onlyRole(MARKET_ADMIN) {
        require(taxAccount != address(0), "Invalid tax account set");
        taxRate = _taxRate;
    }

    function setTaxAccount(address _taxAccount) external onlyRole(MARKET_ADMIN) {
        taxAccount = _taxAccount;
    }

    function pauseMarket() public onlyRole(MARKET_ADMIN) {
        _pause();
    }

    function unpauseMarket() public onlyRole(MARKET_ADMIN) {
        _unpause();
    }
}