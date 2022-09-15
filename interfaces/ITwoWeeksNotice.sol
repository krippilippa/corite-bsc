/**
 *Submitted for verification at Etherscan.io on 2020-11-09
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITwoWeeksNotice {
    function getStakeState(address account)
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            uint64
        );

    function getAccumulated(address account)
        external
        view
        returns (uint128, uint128);

    function estimateAccumulated(address account)
        external
        view
        returns (uint128, uint128);

    function stake(uint64 amount, uint64 unlockPeriod) external;

    function requestWithdraw() external;

    function withdraw(address to) external;
}
