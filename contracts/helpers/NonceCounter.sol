//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract NonceCounter is AccessControl {
    bytes32 public constant NONCE_HANDLER = keccak256("NONCE_HANDLER");

    mapping(address => uint256) public currentNonce;

    constructor(address _defaultAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    modifier isNONCE_HANDLER() {
        require(
            hasRole(NONCE_HANDLER, msg.sender),
            "NONCE_HANDLER role required"
        );
        _;
    }

    function incrementNonce(address _user) external isNONCE_HANDLER {
        currentNonce[_user]++;
    }
}
