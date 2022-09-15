// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ITwoWeeksNotice.sol";

contract COStakeReward is AccessControl {
    ITwoWeeksNotice public twoWeeksNotice;

    constructor(ITwoWeeksNotice _twoWeeksNotice) {
        twoWeeksNotice = _twoWeeksNotice;
    }

    function estimateReward() public view returns (uint) {
        (uint128 accumulated, uint128 accumulatedStrict) = twoWeeksNotice
            .estimateAccumulated(msg.sender);

        uint reward = accumulated / 1460;
        return reward;
    }
}
