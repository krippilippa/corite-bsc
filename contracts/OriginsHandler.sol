// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAWCollection.sol";

contract OriginsHandler is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SERVER = keccak256("SERVER");

    IAWCollection public collection;
    address private coriteAccount;
    mapping (address => mapping (uint => bool)) hasMinted;
    mapping (address => bool) public validToken;
    mapping (uint => uint) public nextId;

    uint groupSize = 100;

    event ValidToken(address indexed tokenAddress, bool valid);

    constructor(IAWCollection _collection, uint _startGroup, uint _groupAmount, address _default_admin_role) {
        collection = _collection;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);

        for (uint256 i = _startGroup; i < _groupAmount; i++) {
            nextId[i * groupSize] = i * groupSize;
        }
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
      //  require(hasMinted[msg.sender][_groupId] == false, "Address has already minted for this group");
        _checkGroupStatus(_groupId);
        bytes memory message = abi.encode(msg.sender, _groupId, _tokenAddress, _tokenAmount);
        require(hasRole(SERVER, ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s)), "Invalid server signature");
        _transferTokens(_tokenAddress, _tokenAmount);
        hasMinted[msg.sender][_groupId] = true;
        _mint(msg.sender, _groupId);
    }

    function mintForUser(address[] calldata _to, uint _groupId) external onlyRole(ADMIN){
        require(nextId[_groupId] + _to.length <= (_groupId + groupSize));
        _checkGroupStatus(_groupId);
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _groupId);
        }
    }

    function mintFullGroup(uint _groupId, address _to) external onlyRole(ADMIN){
        require(nextId[_groupId] == _groupId, "Group already started");
        for (uint256 i = 0; i < groupSize; i++) {
            _mint(_to, _groupId);
        }
    }

    function _mint(address _to, uint _groupId) internal {
        collection.mint(_to, nextId[_groupId]);
        nextId[_groupId]++;
    }

    function setValidToken(address _tokenAddress, bool _valid) external onlyRole(ADMIN) {
        validToken[_tokenAddress] = _valid;
        emit ValidToken(_tokenAddress, _valid);
    }

    function setCoriteAccount(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        coriteAccount = _account;
    }

    function pauseHandler() external onlyRole(ADMIN) {
        _pause();
    }

    function unpauseHandler() external onlyRole(ADMIN) {
        _unpause();
    }

    function _checkValidToken(address _tokenAddress) internal view {
        require(validToken[_tokenAddress] == true, "Invalid token address");
    }

    function _checkGroupStatus(uint _groupId) internal view {
        if(_groupId != 0) {
            require(nextId[_groupId] != 0, "Invalid group id");
        }
        require(nextId[_groupId] <= (_groupId + groupSize), "Group is fully minted");
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
}
