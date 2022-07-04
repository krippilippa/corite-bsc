// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAWCollection {
    function ownerOf(uint _tokenId) external view returns (address);
    function mint(address _to, uint _tokenId) external;
    function burn(uint _tokenId) external;
}