// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMoments.sol";

contract MomentsHandler is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SERVER = keccak256("SERVER");

    IMoments public moments;
    address private coriteAccount;
    uint public maxGroupSize = 1_000_000;

    struct GroupData {
        uint nextId;
        uint amountCap;
        uint maxPerUser;
        bool openMinting;
        bool closed;
        bool ownerCanRedeem;
    }

    mapping (uint => GroupData) public groupData;
    mapping (address => mapping (uint => uint)) public hasMinted;
    mapping (address => mapping (uint => bool)) public canRedeem;
    mapping (address => bool) public validToken;

    event GroupCreated(uint groupId);
    event ValidToken(address indexed tokenAddress, bool valid);

    constructor(IMoments _moments, address _default_admin_role) {
        moments = _moments;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function createGroup(uint _groupId, uint _maxAmount, uint _maxPerUser) external onlyRole(ADMIN){
        require(_groupId != 0 && _groupId < 1_000_000_000, "Invalid groupId");
        require(groupData[_groupId].nextId == 0, "Group already exists");
        require(_maxAmount <= maxGroupSize, "Invalid group size");
        groupData[_groupId] = GroupData({
            nextId: _groupId * maxGroupSize,
            amountCap: _maxAmount == 0 ? ((_groupId + 1) * maxGroupSize) - 1 : _groupId * maxGroupSize + _maxAmount,
            maxPerUser: _maxPerUser,
            openMinting: false,
            closed: false,
            ownerCanRedeem: false
        });       
        emit GroupCreated(_groupId);
    }

    function setGroupClosed(uint _groupId, bool _closed) external onlyRole(ADMIN){
        groupData[_groupId].closed = _closed;
    }

    function claimNFT(uint _groupId) external whenNotPaused {
        require(groupData[_groupId].openMinting, "Unrestricted minting not open");
       _userMint(_groupId);
    }

    function mintUser(
        uint _groupId,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        bytes memory message = abi.encode(msg.sender, _groupId);
        require(hasRole(SERVER, ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s)), "Invalid server signature");
       _userMint(_groupId);
    }

    function mintUserPay(
        uint _groupId,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable whenNotPaused {
        bytes memory message = abi.encode(msg.sender, _groupId, _tokenAddress, _tokenAmount);
        require(hasRole(SERVER, ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s)), "Invalid server signature");
        _transferTokens(_tokenAddress, _tokenAmount);
       _userMint(_groupId);
    }

    function mintForUser(address[] calldata _to, uint _groupId) external onlyRole(ADMIN){
        _checkGroupIsOpen(_groupId);
        _checkMintAmount(_groupId, _to.length);
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _groupId);
        }
    }

    function mintForUserBatch(address[] calldata _to, uint _groupId, uint[] calldata _amounts) external onlyRole(ADMIN){
        require(_to.length == _amounts.length, "Array length mismatch");
        _checkGroupIsOpen(_groupId);
        for (uint256 i = 0; i < _to.length; i++) {
            _checkMintAmount(_groupId, _amounts[i]);
            for (uint256 j = 0; j < _amounts[i]; j++) {
                _mint(_to[i], _groupId);
            }
        }
    }

    function _userMint(uint _groupId) internal {
        _checkGroupIsOpen(_groupId);
        _checkMintAmount(_groupId, 1);
        require(hasMinted[msg.sender][_groupId] < groupData[_groupId].maxPerUser, "Address has already minted max allowed for this group");
        hasMinted[msg.sender][_groupId]++;
        _mint(msg.sender, _groupId);
    }

    function _mint(address _to, uint _groupId) internal {
        moments.mint(_to, groupData[_groupId].nextId);
        groupData[_groupId].nextId++;
    }

    function setOpenMinting(uint _groupId, bool _isOpen) external onlyRole(ADMIN) {
        groupData[_groupId].openMinting = _isOpen;
    }

    function setOwnerCanRedeem(uint _groupId, bool _canRedeem) external onlyRole(ADMIN) {
        groupData[_groupId].ownerCanRedeem = _canRedeem;
    }

    function allowRedeem(address _address, uint _groupId, bool _allowed) external onlyRole(ADMIN) {
        canRedeem[_address][_groupId] = _allowed;
    }

    function setRedeemed(uint _tokenId, uint _redeemId) external whenNotPaused {
        require(hasRole(ADMIN, msg.sender) || canRedeem[msg.sender][getGroupId(_tokenId)] || (moments.ownerOf(_tokenId) == msg.sender && groupData[getGroupId(_tokenId)].ownerCanRedeem == true), "Redeem access denied");
        moments.setRedeemed(_tokenId, _redeemId);
    }

    function pauseHandler() external onlyRole(ADMIN) {
        _pause();
    }

    function unpauseHandler() external onlyRole(ADMIN) {
        _unpause();
    }

    function setValidToken(address _tokenAddress, bool _valid) external onlyRole(ADMIN) {
        validToken[_tokenAddress] = _valid;
        emit ValidToken(_tokenAddress, _valid);
    }

    function setCoriteAccount(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        coriteAccount = _account;
    }

    function getGroupId(uint _tokenId) public view returns (uint) {
        return _tokenId / maxGroupSize;
    }

    function _checkValidToken(address _tokenAddress) internal view {
        require(validToken[_tokenAddress] == true, "Invalid token address");
    }

    function _transferNativeToken(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to transfer native token");
    }

    function _transferTokens(address _tokenAddress, uint256 _tokenAmount) internal {
        if (_tokenAddress == address(0)) {
            require(_tokenAmount == msg.value, "Invalid token amount");
            _transferNativeToken(coriteAccount, msg.value);
        } else {
            _checkValidToken(_tokenAddress);
            IERC20(_tokenAddress).transferFrom(msg.sender, coriteAccount, _tokenAmount);
        }
    }

    function _checkGroupIsOpen(uint _groupId) internal view {
        require(groupData[_groupId].closed == false, "Minting of group is closed");
    }

    function _checkMintAmount(uint _groupId, uint _mintAmount) internal view {
        require(groupData[_groupId].nextId + _mintAmount <= groupData[_groupId].amountCap, "Amount exceeds group amountCap");
    }
}
