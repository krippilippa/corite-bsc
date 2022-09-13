// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract StakingState is AccessControl {

    bytes32 public constant ASSET_PROVIDER = keccak256("ADMIN");

    constructor (address _default_admin_role) {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }
}