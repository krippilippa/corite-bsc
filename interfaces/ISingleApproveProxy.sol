// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISingleApproveProxy {
    function transferFrom(address _token, address _sender, address _recipient, uint256 _amount) external payable;
}