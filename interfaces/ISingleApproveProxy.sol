// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISingleApproveProxy {
    function transferERC20(address _token, address _sender, address _recipient, uint256 _amount) external;

    function transferERC721(address _contract, address _sender, address _recipient, uint256 _token) external;

    function transferERC1155(address _contract, address _sender, address _recipient, uint256 _token, uint256 _amount) external;

    function transferERC1155Batch(address _contract, address _sender, address _recipient, uint256[] calldata _tokens, uint256[] calldata _amounts) external;
}