// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract CO_claim is AccessControl , Pausable{

    IERC20 public CO_token;
    address private serverPubKey;

    mapping (address => uint) public internalNonce;
 
    constructor(IERC20 _CO_token, address _serverPubKey, address _default_admin_role) {
        CO_token = _CO_token;
        serverPubKey = _serverPubKey;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function claimCO(
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused{
        bytes memory message = abi.encode(msg.sender, _amount, internalNonce[msg.sender]);
        bytes memory prefix = "\x19Ethereum Signed Message:\n96";
        require(ecrecover(keccak256(abi.encodePacked(prefix, message)), _v, _r, _s) == serverPubKey, "Signature invalid");
        internalNonce[msg.sender]++;
        CO_token.transfer(msg.sender, _amount);
    }

    function changeServerKey(address _sK) public onlyRole(DEFAULT_ADMIN_ROLE) {
        serverPubKey = _sK;
    }

    function drain(address _receive, uint _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        CO_token.transfer(_receive, _amount);
    }

    function pauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
