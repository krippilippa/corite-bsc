// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ICNR.sol";

contract Moments is ERC721, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");
    bytes32 public constant REDEEMER = keccak256("REDEEMER");

    ICNR private CNR;
    mapping(uint => mapping(uint => bool)) public isRedeemed;

    constructor(ICNR _CNR, address _default_admin_role) ERC721("WOW Moments by Corite", "WOW Moments") {
        CNR = _CNR;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function mint(address _to, uint _tokenId) external onlyRole(MINTER){
        _safeMint(_to, _tokenId);
    }

    function burn(uint _tokenId) external onlyRole(BURNER){
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not owner nor approved");
        _burn(_tokenId);
    }

    function setRedeemed(uint _tokenId, uint _redeemId) external onlyRole(REDEEMER) {
        isRedeemed[_tokenId][_redeemId] = true;
    }

    function getRedeemedList(uint _tokenId, uint[] calldata _redeemIds) external view returns (uint[] memory) {
        return _getRedeemed(_tokenId, _redeemIds);
    }

    function getRedeemedRange(uint _tokenId, uint _startId, uint _endId) external view returns (uint[] memory) {
        uint length = _endId - _startId + 1;
        uint[] memory ids = new uint[](length);
        for (uint256 i = 0; i < length; i++) {
            ids[i] = _startId + i;
        }
        return _getRedeemed(_tokenId, ids);
    }

    function _getRedeemed(uint _tokenId, uint[] memory _redeemIds) internal view returns (uint[] memory) {
        uint length = _redeemIds.length;
        uint foundAmount = 0;
        for (uint256 i = 0; i < length; i++) {
            if(isRedeemed[_tokenId][_redeemIds[i]]) {
                foundAmount++;
            }
        }
        uint[] memory a = new uint[](foundAmount);
        uint nextIndex = 0;
        for (uint256 i = 0; i <length; i++) {
            if(isRedeemed[_tokenId][_redeemIds[i]]) {
               a[nextIndex] = _redeemIds[i];
               nextIndex++;
            }
        }
        return a;
    }
    
    function tokenURI(uint _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return CNR.getNFTURI(address(this), _tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
