// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAWCollection.sol";

contract MomentsHandler is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SERVER = keccak256("SERVER");

    IAWCollection public collection;
    address private coriteAccount;
    mapping (address => mapping (uint => bool)) hasMinted;
    mapping (address => bool) public validToken;
    mapping (uint => uint) public nextId;

    event ValidToken(address indexed tokenAddress, bool valid);

    constructor(IAWCollection _collection, uint _groups, address _default_admin_role) {
        collection = _collection;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);

        for (uint256 i = 0; i < _groups; i++) {
            nextId[i] = i * 100;
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
        require(hasMinted[msg.sender][_groupId] == false, "Address has already minted for this group");
        bytes memory message = abi.encode(_groupId, msg.sender, _tokenAddress, _tokenAmount);
        require(hasRole(SERVER, ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s)), "Invalid server signature");
        _transferTokens(_tokenAddress, _tokenAmount);
        hasMinted[msg.sender][_groupId] = true;
        _mint(msg.sender, _groupId);
    }

    function mintFullGroup(uint _groupId, address _to) external onlyRole(ADMIN){
        for (uint256 i = 0; i < 100; i++) {
            _mint(_to, _groupId);
        }
    }

    function _mint(address _to, uint _groupId) internal {
        collection.mint(_to, nextId[_groupId]);
        nextId[_groupId]++;
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
}
