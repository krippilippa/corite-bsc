//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "interfaces/IChromiaNetResolver.sol";

contract Corite_ERC1155 is ERC1155Supply, AccessControl{

    IChromiaNetResolver private CNR;
    bytes32 public constant CREATE_CLOSE_HANDLER = keccak256("CREATE_CLOSE_HANDLER");
    bytes32 public constant MINTER_BURNER_HANDLER = keccak256("MINTER_BURNER_HANDLER");
    
    uint public nftCollection;
    uint public campaignCount = 1 * (10 ** 68);

    struct Campaign {
        address owner;

        uint valuationUSD;

        uint totalSupply;
        uint maxFundingAllowed;

        bool closed;
    }

    mapping (uint => uint) public nftCount;
    mapping (address => uint[]) public ownedCollections;
    mapping (address => uint[]) public ownedCampaigns;
    mapping (uint => Campaign) public campaignInfo;

    constructor(IChromiaNetResolver _CNR) ERC1155("") {
        CNR = _CNR;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier isCREATE_CLOSE_HANDLER(){
        require(hasRole(CREATE_CLOSE_HANDLER, msg.sender),"CREATE_CLOSE_HANDLER ROLE REQUIRED");
        _;
    }

    modifier isMINTER_BURNER_HANDLER(){
        require(hasRole(MINTER_BURNER_HANDLER, msg.sender),"MINTER_BURNER_HANDLER ROLE REQUIRED");
        _;
    }

    function createCollection(address _owner) external isCREATE_CLOSE_HANDLER() returns(uint collection) {
        nftCollection++;
        ownedCollections[_owner].push(nftCollection);
        collection = getFullCollectionId(nftCollection);
        nftCount[nftCollection] = collection;
    }

    function mintCollectionBatch(uint _collection, uint _amount, address _to) external isMINTER_BURNER_HANDLER() {
        require(_collection > 0 && _collection < nftCollection , "Collection does not exist");
        uint fci = getFullCollectionId(_collection);
        for (uint i = 0; i < _amount; i++) {
            nftCount[_collection]++;
            _mint(_to, fci + nftCount[_collection], 1, "");            
        }
    }

    function mintCollectionSingle(uint _collection, address _to) external isMINTER_BURNER_HANDLER() {
        require(_collection > 0 && _collection <= nftCollection , "Collection does not exist");
        nftCount[_collection]++;
        _mint(_to, getFullCollectionId(_collection) + nftCount[_collection], 1, "");            
    }

    function createCampaign(address _owner, uint _valuationUSD, uint _totalSupply, uint _maxFundingAllowed) external isCREATE_CLOSE_HANDLER() returns(uint){
        require(_totalSupply > 0 && _maxFundingAllowed > 0, "Cannot creat campaign with 0 shares or 0 allowed to sell");
        require(_totalSupply >= _maxFundingAllowed , "supply much be greater or equal to max allowed");

        campaignCount++;
        ownedCampaigns[_owner].push(campaignCount);

        campaignInfo[campaignCount] = Campaign({
            owner: _owner, 
            valuationUSD: _valuationUSD, 
            totalSupply: _totalSupply, 
            maxFundingAllowed: _maxFundingAllowed, 
            closed: false
        });

        return campaignCount;
    }

    function closeCampaign (uint _campaign) external isCREATE_CLOSE_HANDLER() {
        require(campaignInfo[_campaign].totalSupply > 0 , "Campaign does not exist");
        campaignInfo[_campaign].closed = true;
    }

    function mintCampaignShares (uint _campaign, uint _amount, address _to) external isMINTER_BURNER_HANDLER() {
        require(_amount >= (campaignInfo[_campaign].maxFundingAllowed - totalSupply(_campaign)), "Amount exceedes supply");
        require(campaignInfo[_campaign].closed == false, "Campaign.closed == true");
        _mint(_to, _campaign, _amount, "");
    }

    function burnToken(uint256 _fullTokenId, uint256 _amount, address _from) external isMINTER_BURNER_HANDLER() {
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(_from, _fullTokenId, _amount);
    }

    function getFullCollectionId(uint _collection) public pure returns (uint){
        return (2 * (10 ** 68)) + (_collection * (10 ** 48));
    }

    function uri(uint _tokenId) override public view returns (string memory) {
        require(exists(_tokenId), "ERC1155Metadata: URI query for nonexistent token");
        return IChromiaNetResolver(CNR).getNFTURI(address(this), _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
