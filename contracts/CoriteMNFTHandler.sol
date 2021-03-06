// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/ICoriteMNFT.sol";
import "../interfaces/ISingleApproveProxy.sol";

contract CoriteMNFTHandler is AccessControl , Pausable{

    ICoriteMNFT public coriteMNFT;
    ISingleApproveProxy public singleApproveProxy;
    address public coriteAccount;
    address public serverPubKey;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    bool public nativeAllowed;

    mapping (uint => uint) public groupCount;
    mapping (uint => bool) public groupOpen;
    mapping (address => uint) internalNonce;

    event Group(uint group);

    constructor(ICoriteMNFT _coriteMNFT, ISingleApproveProxy _singleApproveProxy, address _default_admin_role) {
        coriteMNFT = _coriteMNFT;
        singleApproveProxy = _singleApproveProxy;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function createGroup(uint _group) external onlyRole(ADMIN){
        require(_group > 999 && _group < 10000);
        groupCount[_group] = _group * 1_000_000;
        groupOpen[_group] = true;
        emit Group(_group);
    }

    function setGroupStatus(uint _group, bool _open) external onlyRole(ADMIN){
        groupOpen[_group] = _open;
    }

    function mintUser(
        uint _group,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused{
        bytes memory message = abi.encode(msg.sender, _group, internalNonce[msg.sender]);
        require(ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s) == serverPubKey, "Signature invalid");
        internalNonce[msg.sender]++;
        require(groupOpen[_group], "Minting of group is closed");
        _mint(msg.sender, _group);
    }

    function mintForUser(address[] calldata _to, uint _group) external onlyRole(ADMIN){
        require(groupOpen[_group], "Minting of group is closed");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _group);
        }
    }

    function mintBatch(address _to, uint _group, uint _nr) external onlyRole(ADMIN){
        require(groupOpen[_group], "Minting of group is closed");
        for (uint256 i = 0; i < _nr; i++) {
            _mint(_to, _group);
        }
    }

    function mintUserPay(
        uint _group,
        address _token,
        uint _price,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable whenNotPaused{
        require(groupOpen[_group], "Minting of group is closed");
        bytes memory message = abi.encode(msg.sender, _group, _token, _price, internalNonce[msg.sender]);
        require(ecrecover(keccak256(abi.encodePacked(_prefix, message)), _v, _r, _s) == serverPubKey, "Signature invalid");
        internalNonce[msg.sender]++;
        if(_token == address(0)){
            require(nativeAllowed == true, "Payment with native token not allowed");
            (bool sent, ) = coriteAccount.call{value: _price}("");
            require(sent, "Failed to transfer native token");
        }else{
            singleApproveProxy.transferERC20(_token, msg.sender, coriteAccount, _price);
        }
        _mint(msg.sender, _group);
    }

    function _mint(address _to, uint _group) internal {
        groupCount[_group]++;
        coriteMNFT.mint(_to, groupCount[_group]);
    }
    
    function updateServer (address _serverPubKey) public onlyRole(DEFAULT_ADMIN_ROLE){
        serverPubKey = _serverPubKey;
    }

    function updateCoriteAccount (address _coriteAccount) public onlyRole(DEFAULT_ADMIN_ROLE){
        coriteAccount = _coriteAccount;
    }

    function updateNativeAllowed (bool _nativeAllowed) public onlyRole(ADMIN){
        nativeAllowed = _nativeAllowed;
    }

    function pauseHandler() public onlyRole(ADMIN) {
        _pause();
    }

    function unpauseHandler() public onlyRole(ADMIN) {
        _unpause();
    }
}
