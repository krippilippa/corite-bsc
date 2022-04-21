// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IChromiaNetResolver.sol";

contract Corite_ERC1155 is ERC1155Supply, AccessControl {
    string public name = "Corite";
    string public symbol = "CORITE";

    IChromiaNetResolver private CNR;

    bytes32 public constant CREATE_CLOSE_HANDLER = keccak256("CREATE_CLOSE_HANDLER");
    bytes32 public constant MINTER_NONCE_HANDLER = keccak256("MINTER_NONCE_HANDLER");
    bytes32 public constant BURNER_HANDLER = keccak256("BURNER_HANDLER");

    uint public latestCollectionId = 2 * (10 ** 68);
    uint public campaignCount = 1 * (10 ** 68);

    struct Campaign {
        address owner;

        uint supplyCap;
        uint toBackersCap;
        bool hasMintedExcess;

        bool closed;
        bool cancelled;
    }

    struct Collection {
        address owner;

        uint maxTokenId;
        uint latestTokenId;

        bool closed;
    }

    mapping (address => uint[]) public ownedCollections;
    mapping (uint => Collection) public collectionInfo;

    mapping (address => uint[]) public ownedCampaigns;
    mapping (uint => Campaign) public campaignInfo;

    mapping(address => uint256) public currentNonce;

    event CreateCampaignEvent(address indexed owner, uint campaignId);
    event CloseCampaignEvent(uint campaignId);
    event CancelCampaignEvent(uint campaignId, bool cancelled);

    event CreateCollectionEvent(address indexed owner, uint collectionId);
    event CloseCollectionEvent(uint collectionId);

    constructor(IChromiaNetResolver _CNR, address _default_admin_role) ERC1155("") {
        CNR = _CNR;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    modifier isCREATE_CLOSE_HANDLER(){
        require(hasRole(CREATE_CLOSE_HANDLER, msg.sender), "CREATE_CLOSE_HANDLER role required");
        _;
    }

    modifier isMINTER_NONCE_HANDLER(){
        require(hasRole(MINTER_NONCE_HANDLER, msg.sender), "MINTER_NONCE_HANDLER role required");
        _;
    }

    function createCollection(address _owner, uint _totalSupply) external isCREATE_CLOSE_HANDLER returns(uint) {
        require(_totalSupply > 0, "Invalid totalSupply");
        latestCollectionId += (10 ** 60);
        ownedCollections[_owner].push(latestCollectionId);
        collectionInfo[latestCollectionId] = Collection({
            owner: _owner, 
            maxTokenId: latestCollectionId + _totalSupply, 
            latestTokenId: latestCollectionId, 
            closed: false
        });
        emit CreateCollectionEvent(_owner, latestCollectionId);
        return latestCollectionId;
    }

    function mintCollectionBatch(uint _collection, uint _amount, address _to) external isMINTER_NONCE_HANDLER {
         _checkCollection(_collection);
        require(collectionInfo[_collection].latestTokenId + _amount <= collectionInfo[_collection].maxTokenId , "Amount exceeds supply cap");
        for (uint i = 0; i < _amount; i++) {
            collectionInfo[_collection].latestTokenId++;
            _mint(_to, collectionInfo[_collection].latestTokenId, 1, "");            
        }
    }

    function mintCollectionSingle(uint _collection, address _to) external isMINTER_NONCE_HANDLER {
        _checkCollection(_collection);
        require(collectionInfo[_collection].latestTokenId < collectionInfo[_collection].maxTokenId , "Minting cap reached");
        collectionInfo[_collection].latestTokenId++;
        _mint(_to, collectionInfo[_collection].latestTokenId, 1, "");            
    }

    function closeCollection(uint _collection) external isCREATE_CLOSE_HANDLER {
        require(collectionInfo[_collection].maxTokenId > 0 , "Invalid collection");
        collectionInfo[_collection].closed = true;
        emit CloseCollectionEvent(_collection);
    }

    function createCampaign(address _owner, uint _supplyCap, uint _toBackersCap) external isCREATE_CLOSE_HANDLER returns(uint){
        require(_supplyCap > 0 && _toBackersCap > 0, "supplyCap/toBackersCap must be greater than 0");
        require(_supplyCap >= _toBackersCap , "supplyCap is less than toBackersCap");

        campaignCount++;
        ownedCampaigns[_owner].push(campaignCount);

        campaignInfo[campaignCount] = Campaign({
            owner: _owner, 
            supplyCap: _supplyCap, 
            toBackersCap: _toBackersCap,
            hasMintedExcess: false,
            closed: false,
            cancelled: false
        });
        emit CreateCampaignEvent(_owner, campaignCount);
        return campaignCount;
    }

    function closeCampaign(uint _campaign) external isCREATE_CLOSE_HANDLER {
        _checkCampaign(_campaign);
        campaignInfo[_campaign].closed = true;
        emit CloseCampaignEvent(_campaign);
    }

    function setCampaignCancelled(uint _campaign, bool _cancelled) external isCREATE_CLOSE_HANDLER {
        _checkCampaign(_campaign);
        campaignInfo[_campaign].cancelled = _cancelled;
        emit CancelCampaignEvent(_campaign, _cancelled);
    }

    function mintCampaignShares(uint _campaign, uint _amount, address _to) external isMINTER_NONCE_HANDLER {
        require(campaignInfo[_campaign].closed == false && campaignInfo[_campaign].cancelled == false, "Campaign closed/cancelled");
        require(_amount > 0, "Amount can not be 0");
        if(campaignInfo[_campaign].hasMintedExcess == true) {
            require(_amount <= (campaignInfo[_campaign].supplyCap - totalSupply(_campaign)), "Amount exceeds supplyCap");
        } else {
            require(_amount <= (campaignInfo[_campaign].toBackersCap - totalSupply(_campaign)), "Amount exceeds toBackersCap");
        }
        _mint(_to, _campaign, _amount, "");
    }

    function mintExcessShares(uint _campaign, address _to) external isMINTER_NONCE_HANDLER {
        require(campaignInfo[_campaign].hasMintedExcess == false || campaignInfo[_campaign].cancelled == false, "Excess shares already minted");
        campaignInfo[_campaign].hasMintedExcess = true;
        _mint(_to, _campaign, campaignInfo[_campaign].supplyCap - campaignInfo[_campaign].toBackersCap, "");
    }

    function burnToken(uint256 _fullTokenId, uint256 _amount, address _from) external {
        require(hasRole(BURNER_HANDLER, msg.sender), "BURNER_HANDLER role required");
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(_from, _fullTokenId, _amount);
    }

    function incrementNonce(address _user) external isMINTER_NONCE_HANDLER {
        currentNonce[_user]++;
    }

    function getCampaignCount(address _owner) external view returns (uint256) {
        return ownedCampaigns[_owner].length;
    }

    function getCollectionCount(address _owner) external view returns (uint256) {
        return ownedCollections[_owner].length;
    }

    function uri(uint _tokenId) override public view returns (string memory) {
        require(exists(_tokenId), "ERC1155Metadata: URI query for nonexistent token");
        return IChromiaNetResolver(CNR).getNFTURI(address(this), _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _checkCollection(uint _id) internal view {
        require(collectionInfo[_id].closed == false, "Collection closed");
    }

    function _checkCampaign(uint _id) internal view {
        require(campaignInfo[_id].supplyCap > 0 , "Campaign not exist");
    }
}
