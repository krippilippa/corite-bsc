// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ITwoWeeksNotice.sol";

contract COStake is AccessControl {
    ITwoWeeksNotice public twoWeeksNotice;
    IERC20 public token;
    mapping(address => uint) claimedCO;

    constructor(ITwoWeeksNotice _twoWeeksNotice, IERC20 _token) {
        twoWeeksNotice = _twoWeeksNotice;
        token = _token;
    }

    function estimateYield() public view returns (uint) {
        (uint128 accumulated, uint128 accumulatedStrict) = twoWeeksNotice
            .estimateAccumulated(msg.sender);

        uint yield = accumulatedStrict / 1460 - claimedCO[msg.sender];
        return yield;
    }

    function claimYield() external {
        uint claimableYield = estimateYield();
        require(claimableYield > 0, "No claimable yield");
        claimedCO[msg.sender] += claimableYield;
        token.transfer(msg.sender, claimableYield);
    }
}
