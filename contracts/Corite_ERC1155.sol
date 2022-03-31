//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "interfaces/IChromiaNetResolver.sol";

contract Corite_ERC1155 is ERC1155Supply, AccessControl{

    IChromiaNetResolver private CNR;
    bytes32 public constant CREATE_CLOSE_HANDLER = keccak256("CREATE_CLOSE_HANDLER");
    bytes32 public constant MINTER_HANDLER = keccak256("MINTER_HANDLER");
    bytes32 public constant BURNER_HANDLER = keccak256("BURNER_HANDLER");
    
    uint public nftCollection;
    uint public campaignCount = 1 * (10 ** 68);

    struct Campaign {
        address owner;

        uint valuationUSD;

        uint totalSupply;
        uint maxFundingAllowed;

        bool closed;
        bool cancelled;
    }

    struct Collection {
        address owner;

        uint totalSupply;
        uint minted;

        bool closed;
    }

    mapping (address => uint[]) public ownedCollections;
    mapping (uint => Collection) public collectionInfo;

    mapping (address => uint[]) public ownedCampaigns;
    mapping (uint => Campaign) public campaignInfo;

    event CreateCampaignEvent(address owner, uint campaignId);
    event CreateCollectionEvent(address owner, uint collectionId);
    event CloseCampaignEvent(uint campaignId);
    event CancelCampaignEvent(uint campaignId, bool cancelled);

    constructor(IChromiaNetResolver _CNR, address _default_admin_role) ERC1155("") {
        CNR = _CNR;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    modifier isCREATE_CLOSE_HANDLER(){
        require(hasRole(CREATE_CLOSE_HANDLER, msg.sender),"CREATE_CLOSE_HANDLER ROLE REQUIRED");
        _;
    }

    modifier isMINTER_HANDLER(){
        require(hasRole(MINTER_HANDLER, msg.sender),"MINTER_HANDLER ROLE REQUIRED");
        _;
    }

    modifier isBURNER_HANDLER(){
        require(hasRole(BURNER_HANDLER, msg.sender),"BURNER_HANDLER ROLE REQUIRED");
        _;
    }

    function createCollection(address _owner, uint _totalSupply) external isCREATE_CLOSE_HANDLER() returns(uint collection) {
        require(_totalSupply > 0, "Cap can not be 0");
        nftCollection++;
        collection = getFullCollectionId(nftCollection);
        ownedCollections[_owner].push(collection);
        collectionInfo[collection] = Collection({owner: _owner, totalSupply: _totalSupply, minted: collection, closed: false});
        emit CreateCollectionEvent(_owner, collection);
    }

    function mintCollectionBatch(uint _collection, uint _amount, address _to) external isMINTER_HANDLER() {
        require(collectionInfo[_collection].closed == false, "Collection.closed == true");
        require(collectionInfo[_collection].minted + _amount <= collectionInfo[_collection].totalSupply , "Amount exceeds supply");
        for (uint i = 0; i < _amount; i++) {
            collectionInfo[_collection].minted++;
            _mint(_to, collectionInfo[_collection].minted, 1, "");            
        }
    }

    function mintCollectionSingle(uint _collection, address _to) external isMINTER_HANDLER() {
        collectionInfo[_collection].minted++;
        require(collectionInfo[_collection].closed == false, "Collection.closed == true");
        require(collectionInfo[_collection].minted <= collectionInfo[_collection].totalSupply , "Minted exceeds supply");
        _mint(_to, collectionInfo[_collection].minted, 1, "");            
    }

    function createCampaign(address _owner, uint _valuationUSD, uint _totalSupply, uint _maxFundingAllowed) external isCREATE_CLOSE_HANDLER() returns(uint){
        require(_totalSupply > 0 && _maxFundingAllowed > 0, "Cannot creat campaign with 0 shares or 0 allowed to sell");
        require(_totalSupply >= _maxFundingAllowed , "Supply much be greater or equal to max allowed");

        campaignCount++;
        ownedCampaigns[_owner].push(campaignCount);

        campaignInfo[campaignCount] = Campaign({
            owner: _owner, 
            valuationUSD: _valuationUSD, 
            totalSupply: _totalSupply, 
            maxFundingAllowed: _maxFundingAllowed, 
            closed: false,
            cancelled: false
        });
        emit CreateCampaignEvent(_owner, campaignCount);
        return campaignCount;
    }

    function closeCampaign(uint _campaign) external isCREATE_CLOSE_HANDLER() {
        require(campaignInfo[_campaign].totalSupply > 0 , "Campaign does not exist");
        campaignInfo[_campaign].closed = true;
        emit CloseCampaignEvent(_campaign);
    }

    function setCampaignCancelled(uint _campaign, bool _cancelled) external isBURNER_HANDLER() {
        require(campaignInfo[_campaign].totalSupply > 0 , "Campaign does not exist");
        campaignInfo[_campaign].cancelled = _cancelled;
        emit CancelCampaignEvent(_campaign, _cancelled);
    }

    function mintCampaignShares(uint _campaign, uint _amount, address _to) external isMINTER_HANDLER() {
        require(_amount >= (campaignInfo[_campaign].maxFundingAllowed - totalSupply(_campaign)), "Amount exceedes supply");
        require(campaignInfo[_campaign].closed == false, "Campaign.closed == true");
        _mint(_to, _campaign, _amount, "");
    }

    function burnToken(uint256 _fullTokenId, uint256 _amount, address _from) external isBURNER_HANDLER() {
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(_from, _fullTokenId, _amount);
    }

    function getFullCollectionId(uint _collection) public pure returns (uint){
        return (2 * (10 ** 68)) + (_collection * (10 ** 60));
    }

    function uri(uint _tokenId) override public view returns (string memory) {
        require(exists(_tokenId), "ERC1155Metadata: URI query for nonexistent token");
        return IChromiaNetResolver(CNR).getNFTURI(address(this), _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
