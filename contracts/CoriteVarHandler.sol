// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICoriteMNFT.sol";

contract CoriteVarHandler is AccessControl, Pausable {

    ICoriteMNFT public coriteMNFT;
    address private coriteAccount;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SERVER = keccak256("SERVER");

    bool openMinting = false;

    mapping (uint => uint) public groupCount;
    mapping (uint => uint) public groupRoof;
    mapping (uint => bool) public groupOpen;
    mapping (address => mapping (uint => bool)) hasMinted;
    mapping(address => bool) public validToken;

    event Group(uint group);
    event ValidToken(address indexed tokenAddress, bool valid);

    constructor(ICoriteMNFT _coriteMNFT, address _default_admin_role) {
        coriteMNFT = _coriteMNFT;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function createGroup(uint _group, uint _nrInGroup) external onlyRole(ADMIN){
        require(_group > 1001 && _group < 1100);
        groupCount[_group] = _group * 1_000_000;
        if (_nrInGroup == 0){
            groupRoof[_group] = 0;
        }else {
            groupRoof[_group] = groupCount[_group] + _nrInGroup;
        }
        groupOpen[_group] = true;
        emit Group(_group);
    }

    function setGroupStatus(uint _group, bool _open) external onlyRole(ADMIN){
        groupOpen[_group] = _open;
    }

    function claimNFT(uint _group) external whenNotPaused {
        require(openMinting, "Unrestricted minting not open");
       _userMint(_group);
    }

    function mintUser(
        uint _group,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        bytes memory message = abi.encode(msg.sender, _group);
        require(hasRole(SERVER, ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s)), "Invalid server signature");
       _userMint(_group);
    }

    function mintUserPay(
        uint _group,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        bytes memory message = abi.encode(msg.sender, _group, _tokenAddress, _tokenAmount);
        require(hasRole(SERVER, ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s)), "Invalid server signature");
        _transferTokens(_tokenAddress, _tokenAmount);
       _userMint(_group);
    }

    function mintForUser(address[] calldata _to, uint _group) external onlyRole(ADMIN){
        require(groupOpen[_group] == true, "Minting of group is closed");
        require(groupCount[_group] + _to.length <= groupRoof[_group], "Can not mint these many nfts");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _group);
        }
    }

    function mintBatch(address _to, uint _group, uint _nr) external onlyRole(ADMIN){
        require(groupOpen[_group], "Minting of group is closed");
        require(groupCount[_group] + _nr <= groupRoof[_group], "Can not mint these many nfts");
        for (uint256 i = 0; i < _nr; i++) {
            _mint(_to, _group);
        }
    }

    function _userMint(uint _group) internal {
        require(groupOpen[_group], "Minting of group is closed");
        require(hasMinted[msg.sender][_group] == false, "This address has already minted an nft for this group");
        hasMinted[msg.sender][_group] = true;
        if(groupRoof[_group] == 0){
            _mint(msg.sender, _group);
        } else {
            require(groupCount[_group] < groupRoof[_group], "No more NFTs to mint in this group");
            _mint(msg.sender, _group);
        }
    }

    function _mint(address _to, uint _group) internal {
        groupCount[_group]++;
        coriteMNFT.mint(_to, groupCount[_group]);
    }


    function setOpenMinting(bool _isOpen) external onlyRole(ADMIN) {
        openMinting = _isOpen;
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
