// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ICNR.sol";

contract CoriteMNFT is ERC721, AccessControl {

    ICNR private CNR;

    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");

    constructor(ICNR _CNR, address _default_admin_role) ERC721("Corite Various", "CO-Various") {
        CNR = _CNR;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function mint(address _to, uint _tokenId) external onlyRole(MINTER){
        _safeMint(_to, _tokenId);
    }

    function burn(uint _tokenId) external onlyRole(BURNER){
        _burn(_tokenId);
    }
    
    function tokenURI(uint _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return ICNR(CNR).getNFTURI(address(this), _tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
