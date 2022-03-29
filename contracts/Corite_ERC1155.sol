//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "interfaces/IChromiaNetResolver.sol";

contract Corite_ERC1155 is ERC1155Supply, AccessControl{

    IChromiaNetResolver private CNR;

    uint256 public nftCollection;
    uint256 public campaignCount = 1 * (10 ** 68);

    struct Campaign {
        address owner;

        uint valuationUSD;

        uint totalSupply;
        uint maxFundingAllowed;
        uint minted;

        bool closed;
    }

    mapping (uint256 => uint256) public nftCount;
    mapping (address => uint256[]) public ownedCollections;
    mapping (address => uint256[]) public ownedCampaigns;
    mapping (uint256 => Campaign) public campaignInfo;

    constructor(IChromiaNetResolver _CNR) ERC1155("") {
        CNR = _CNR;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function createCollection(address _owner) external returns(uint collection) { // must be handler etc to handle constraints 
        nftCollection++;
        ownedCollections[_owner].push(nftCollection);
        collection = getFullCollectionId(nftCollection);
    }

    function mintCollectionBatch(uint _collection, uint _amount, address _to) external { // must be handler etc to handle constraints 
        require(_collection > 0 && _collection < nftCollection , "Collection does not exist");
        if(nftCount[_collection] == 0){
            nftCount[_collection] = getFullCollectionId(_collection);
        }
        for (uint256 i = 0; i < _amount; i++) {
            nftCount[_collection]++;
            _mint(_to, nftCount[_collection], 1, "");            
        }
    }

    function createCampaign(
        address _owner,
        uint _valuationUSD,
        uint _totalSupply,
        uint _maxFundingAllowed
    ) external returns(uint){ // must be handler etc to handle constraints 
        require(_totalSupply > 0 && _maxFundingAllowed > 0, "Cannot creat campaign with 0 shares or 0 allowed to sell");
        require(_totalSupply >= _maxFundingAllowed , "supply much be greater or equal to max allowed");

        campaignCount++;
        ownedCampaigns[_owner].push(campaignCount);

        campaignInfo[campaignCount] = Campaign({
            owner: _owner, 
            valuationUSD: _valuationUSD, 
            totalSupply: _totalSupply, 
            maxFundingAllowed: _maxFundingAllowed, 
            minted: 0, 
            closed: false
        });

        return campaignCount;
    }

    function mintCampaign (uint _campaign, uint _amount, address _to) external {
        require(_amount >= (campaignInfo[_campaign].maxFundingAllowed - campaignInfo[_campaign].minted), "Amount exceedes supply");
        require(campaignInfo[_campaign].closed == false, "Campaign.closed == true");
        campaignInfo[_campaign].minted = campaignInfo[_campaign].minted + _amount;
        _mint(_to, _campaign, _amount, "");
    }

    function getFullCollectionId(uint _collection) public pure returns (uint){
        return (2 * (10 ** 68)) + (_collection * (10 ** 48));
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(exists(_tokenId), "ERC1155Metadata: URI query for nonexistent token");
        return IChromiaNetResolver(CNR).getNFTURI(address(this), _tokenId);
    }
}
