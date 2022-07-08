// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// contract Marketplace is AccessControl, Pausable {
//     bytes32 public constant MARKET_ADMIN = keccak256("MARKET_ADMIN");

//     IERC1155 campaigns;
//     uint public taxRate;
//     address private taxAccount;

//     struct CampaignListing {
//         address owner;
//         uint amount;
//         address currency;
//         uint price;
//     }

//     struct NFTListing {
//         address owner;
//         address currency;
//         uint price;
//     }

//     struct CampaignOffer {
//         address buyer;
//         uint amount;
//         address currency;
//         uint price;
//     }

//     struct NFTOffer {
//         address buyer;
//         address currency;
//         uint price;
//     }

//     mapping(address => bool) public validTokens;

//     mapping(uint => uint) public latestCampaignListId;
//     mapping(uint => uint) public latestCampaignOfferId;

//     mapping (uint=> mapping(address => uint)) public addressListingId;
//     mapping (address => uint) public addressOfferId;

//     mapping(uint => mapping(uint => CampaignListing)) public listedCampaigns;
//     mapping(uint => mapping(uint => CampaignOffer)) public campaignOffers;

//     mapping(address => mapping(uint => NFTListing)) public listedNFTs;
//     mapping(address => mapping(uint => NFTOffer)) public NFTOffers;

//     event AddCampaignListing(uint indexed campaignId, address indexed owner, uint amount, address currency, uint price);
//     event RemoveCampaignListing(uint indexed campaignId, address indexed owner, uint amount);
//     event PlaceCampaignOffer(uint indexed campaignId, address indexed buyer, uint price);
//     event RemovedCampaignOffer(uint indexed tokenId, address indexed buyer);
//     event BoughtCampaignShares(uint indexed campaignId, address indexed seller, address indexed buyer, uint amount, address currency, uint price);

//     event AddNFTListing(address indexed owner, uint amount, address currency, uint price);
//     event RemoveNFTListing(uint indexed tokenId, address indexed owner);
//     event PlaceNFTOffer(uint indexed tokenId, address indexed buyer, uint price);
//     event RemovedNFTOffer(uint indexed tokenId, address indexed buyer);
//     event BoughtNFT(address indexed collection, uint indexed tokenId, address indexed seller, address indexed buyer, address currency, uint price);

//     constructor(IERC1155 _campaigns, address _taxAccount, uint _taxRate, address _default_admin) {
//         campaigns = _campaigns;
//         taxAccount = _taxAccount;
//         taxRate = _taxRate;
//         _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
//     }

//     function addCampaignListing(uint _campaignId, uint _amount, address _currency, uint _price) external whenNotPaused {
//         require(campaigns.balanceOf(msg.sender, _campaignId) >= _amount, "Invalid token amount");
//         require(_price > 0, "Listing price can not be 0");
//         require(_amount > 0, "Amount can not be 0");
//         require(validTokens[_currency], "Invalid currency token");
        
//         latestCampaignListId[_campaignId]++;
//         uint id = latestCampaignListId[_campaignId];
//         listedCampaigns[_campaignId][id] = CampaignListing({owner: msg.sender, amount: _amount, currency: _currency, price: _price});
//         emit AddCampaignListing(_campaignId, msg.sender, _amount, _currency, _price);
//     }

//     function removeCampaignListing(uint _campaignId) external whenNotPaused {
//         require(items.ownerOf(_campaignId) == msg.sender, "Invalid token owner");
//         delete listedItems[_tokenId];
//         emit RemoveCampaignListing(_campaignId, msg.sender);
//     }

//     function buyCampaignShares(uint _campaignId, uint _price) external whenNotPaused {
//         require(listedItems[_tokenId].price > 0, "Invalid token id");
//         require(listedItems[_tokenId].price == _price, "Invalid token price");

//         uint tax = (listedItems[_tokenId].price * taxRate) / 100;

//         DAR.transferFrom(msg.sender, taxAccount, tax);
//         DAR.transferFrom(msg.sender, listedItems[_tokenId].owner, listedItems[_tokenId].price - tax);
//         items.safeTransferFrom(listedItems[_tokenId].owner, msg.sender, _tokenId);

//         delete listedItems[_tokenId];
//         emit BoughtItem(_tokenId, listedItems[_tokenId].owner, msg.sender, _price);
//     }

//     function setValidToken(address _token, bool _valid) external onlyRole(MARKET_ADMIN) {
//         validTokens[_token] = _valid;
//     }

//     function setTaxRate(uint _taxRate) external onlyRole(MARKET_ADMIN) {
//         taxRate = _taxRate;
//     }

//     function setTaxAccount(address _taxAccount) external onlyRole(MARKET_ADMIN) {
//         taxAccount = _taxAccount;
//     }

//      function pauseMarket() public onlyRole(MARKET_ADMIN) {
//         _pause();
//     }
//     function unpauseMarket() public onlyRole(MARKET_ADMIN) {
//         _unpause();
//     }
// }
