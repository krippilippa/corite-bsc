// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INonceCounter {
    function currentNonce(address _user) external returns (uint256);

    function incrementNonce(address _user) external;
}
