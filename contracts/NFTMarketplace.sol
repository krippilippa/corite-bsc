// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace is AccessControl, Pausable {
    bytes32 public constant MARKET_ADMIN = keccak256("MARKET_ADMIN");

    uint public taxRate;
    address private taxAccount;

    struct Listing {
        uint tokenId;
        address owner;
        address currency;
        uint price;
    }

    mapping(address => bool) public validTokens;
    mapping(address=> uint) public latestListId;
    mapping(address => mapping(uint => uint)) public tokenListId;
    mapping(address => mapping(uint => Listing)) public listedNFTs;

    event AddListing(address indexed collection, uint indexed tokenId, address indexed owner, address currency, uint price);
    event RemoveListing(address indexed collection, uint indexed tokenId);
    event BoughtNFT(address indexed collection, uint indexed tokenId, address seller, address indexed buyer, address currency, uint price);

    constructor(address _taxAccount, uint _taxRate, address _default_admin) {
        taxAccount = _taxAccount;
        taxRate = _taxRate;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
    }

    function addListing(address _collection, uint _tokenId, address _currency, uint _price) external whenNotPaused {
        require(IERC721(_collection).ownerOf(_tokenId) == msg.sender, "Invalid token owner");
        require(_price > 0, "Listing price can not be 0");
        require(validTokens[_currency], "Invalid currency token");
        
        latestListId[_collection]++;
        uint id = latestListId[_collection];
        tokenListId[_collection][_tokenId] = id;
        listedNFTs[_collection][id] = Listing({tokenId: _tokenId, owner: msg.sender, currency: _currency, price: _price});
        emit AddListing(_collection, _tokenId, msg.sender, _currency, _price);
    }

    function removeListing(address _collection, uint _tokenId) external whenNotPaused {
        require(IERC721(_collection).ownerOf(_tokenId) == msg.sender, "Invalid token owner");
        delete listedNFTs[_collection][tokenListId[_collection][_tokenId]];
        emit RemoveListing(_collection, _tokenId);
    }

    function buyNFT(address _collection, uint _tokenId, address _currency, uint _price) external whenNotPaused {
        Listing memory listing = listedNFTs[_collection][tokenListId[_collection][_tokenId]];
        require(listing.currency == _currency && listing.price == _price, "Price mis-match");

        uint tax = (listing.price * taxRate) / 100;

        IERC20(listing.currency).transferFrom(msg.sender, taxAccount, tax);
        IERC20(listing.currency).transferFrom(msg.sender, listing.owner, listing.price - tax);
        IERC721(_collection).safeTransferFrom(listing.owner, msg.sender, _tokenId);

        delete listedNFTs[_collection][tokenListId[_collection][_tokenId]];
        emit BoughtNFT(_collection, _tokenId, listing.owner, msg.sender, _currency, _price);
    }

    function getListData(address _collection, uint _tokenId) external view returns (Listing memory) {
        return listedNFTs[_collection][tokenListId[_collection][_tokenId]];
    }

    function getActiveListings(address _collection) external view returns (Listing[] memory) {
        uint maxId = latestListId[_collection];
        Listing[] memory listings = new Listing[](maxId);
        uint activeCount;
        for (uint256 i = 1; i <= maxId; i++) {
            if(listedNFTs[_collection][i].price != 0) {
                listings[i-1] = listedNFTs[_collection][i];
                activeCount++;
            }
        }
        Listing[] memory activeListings = new Listing[](activeCount);
        uint nextId;
        for (uint256 i = 0; i < maxId; i++) {
            if(listings[i].price != 0) {
                activeListings[nextId] = listings[i];
                nextId++;
            }
        }
        return activeListings;
    }

    function setValidToken(address _token, bool _valid) external onlyRole(MARKET_ADMIN) {
        validTokens[_token] = _valid;
    }

    function setTaxRate(uint _taxRate) external onlyRole(MARKET_ADMIN) {
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
