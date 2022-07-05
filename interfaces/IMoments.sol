// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoments {
    function ownerOf(uint _tokenId) external view returns (address);
    function mint(address _to, uint _tokenId) external;
    function burn(uint _tokenId) external;
    function setRedeemed(uint _tokenId, uint _redeemId) external;
}