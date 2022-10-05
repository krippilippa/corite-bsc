// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CoriteMNFT is ERC721, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");

    constructor(address _default_admin_role, uint _amount)
        ERC721("Corite Various", "CO-Various")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function mint(address _to, uint _tokenId) external onlyRole(MINTER) {
        _safeMint(_to, _tokenId);
    }

    function burn(uint _tokenId) external {
        _burn(_tokenId);
    }

    function tokenURI(uint _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
