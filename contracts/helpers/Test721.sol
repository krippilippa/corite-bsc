// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Test721 is ERC721 {

    constructor (uint _amount) ERC721 ("Corite NFT Collection", "Corite-Collection") {
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, i);     
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}