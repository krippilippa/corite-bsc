// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Test1155 is ERC1155 {

    constructor (uint _tokens, uint _amount, address[] memory _mintTo) ERC1155 ("") {
        for (uint256 i = 0; i < _tokens; i++) {
            _mint(msg.sender, i, _amount, "");      
        }
        for (uint256 i = 0; i < _mintTo.length; i++) {
            for (uint256 j = 0; j < _tokens; j++) {
                _mint(_mintTo[i], j, _amount, "");      
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
