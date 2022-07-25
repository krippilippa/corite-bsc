// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BatchTransfer is AccessControl {

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function batchTransfer(IERC721 _contract, address _recipient, uint[] calldata _tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _contract.transferFrom(msg.sender, _recipient, _tokenIds[i]);
        }
    }
}
