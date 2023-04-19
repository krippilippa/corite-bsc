// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Whitelist is AccessControlUpgradeable {
    bytes32 public constant WHITELISTER = keccak256("WHITELISTER");

    mapping(address => bool) public whitelist;

    event AddToWhitelist(address indexed wallet);
    event RemoveFromWhitelist(address indexed wallet);

    function addToWhitelist(
        address[] calldata _addresses
    ) public onlyRole(WHITELISTER) {
        for (uint256 index = 0; index < _addresses.length; index++) {
            whitelist[_addresses[index]] = true;
            emit AddToWhitelist(_addresses[index]);
        }
    }

    function removeFromWhitelist(
        address[] calldata _addresses
    ) public onlyRole(WHITELISTER) {
        for (uint256 index = 0; index < _addresses.length; index++) {
            whitelist[_addresses[index]] = false;
            emit RemoveFromWhitelist(_addresses[index]);
        }
    }
}
