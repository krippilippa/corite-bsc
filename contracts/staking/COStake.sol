/**
 *Submitted for verification at Etherscan.io on 2020-11-09
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract COStake is AccessControl {
    struct StakeState {
        uint64 balance;
        uint64 unlockPeriod; // time it takes from requesting withdraw to being able to withdraw
        uint64 lockedUntil; // 0 if withdraw is not requested
        uint64 since;
        uint accumulatedYield; // how much unclaimed yield is available to the user
    }

    event StakeUpdate(address indexed from, uint64 balance);
    event WithdrawRequest(address indexed from, uint64 until);

    mapping(address => StakeState) private _states;

    uint[] private yieldRates; // the yield rates in the format of (1/yieldrate)*365, e.g. yield rate 10% is expressed as 3650. This is open for improvement.
    uint[] private yieldRateDates; // the date in which the corresponding yieldrate was applied.

    IERC20 private token;

    constructor(IERC20 _token, uint initialRate) {
        token = _token;
        yieldRates.push(initialRate);
        yieldRateDates.push(block.timestamp);
    }

    function getStakeState(address account)
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            uint64
        )
    {
        StakeState storage ss = _states[account];
        return (ss.balance, ss.unlockPeriod, ss.lockedUntil, ss.since);
    }

    function setYieldRate(uint _yieldRate) public {
        yieldRates.push(_yieldRate);
        yieldRateDates.push(block.timestamp);
    }

    function pauseYield() external {
        uint MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        setYieldRate(MAX_INT);
    }

    function calculateAccumulatedYield(StakeState storage ss)
        internal
        view
        returns (uint)
    {
        uint yield = ss.accumulatedYield;
        if (ss.balance > 0) {
            uint256 until = block.timestamp;
            if (ss.lockedUntil > 0 && ss.lockedUntil < block.timestamp) {
                until = ss.lockedUntil;
            }
            uint delta;
            if (until > ss.since) {
                if (ss.lockedUntil == 0) {
                    // below calculates the delta in yield since ss.since
                    uint last;
                    for (uint i = 0; i < yieldRates.length; i++) {
                        // find the earliest applicable yield rate based on ss.since and loop through all the
                        // following yieldrates/dates
                        if (yieldRateDates[i] < ss.since) {
                            continue;
                        } else {
                            last = yieldRateDates[i - 1] < ss.since
                                ? ss.since
                                : yieldRateDates[i - 1];
                            delta =
                                ((ss.balance * (yieldRateDates[i] - last)) /
                                    86400) /
                                yieldRates[i - 1]; // calculate the delta for a specific yield period
                            yield += delta;
                        }
                    }
                    // finally calculate the delta of latest yield rate up to current date
                    last = yieldRateDates[yieldRateDates.length - 1] < ss.since
                        ? ss.since
                        : yieldRateDates[yieldRateDates.length - 1];
                    delta =
                        ((ss.balance * (until - last)) / 86400) /
                        yieldRates[yieldRates.length - 1];
                    yield += delta;
                }
            }
        }
        return (yield);
    }

    function estimateAccumulatedYield(address account)
        public
        view
        returns (uint)
    {
        StakeState storage ss = _states[account];
        return calculateAccumulatedYield(ss);
    }

    function updateAccumulatedYield(StakeState storage ss) private {
        uint _accumulatedYield = calculateAccumulatedYield(ss);
        ss.accumulatedYield = _accumulatedYield;
    }

    function stake(uint64 amount, uint64 unlockPeriod) external {
        StakeState storage ss = _states[msg.sender];
        require(amount > 0, "amount must be positive");
        require(ss.balance <= amount, "cannot decrease balance");
        require(
            unlockPeriod <= 1000 days,
            "unlockPeriod cannot be higher than 1000 days"
        );
        require(
            ss.unlockPeriod <= unlockPeriod,
            "cannot decrease unlock period"
        );
        require(
            unlockPeriod >= 2 weeks,
            "unlock period can't be less than 2 weeks"
        );

        updateAccumulatedYield(ss);

        uint128 delta = amount - ss.balance;
        if (delta > 0) {
            require(
                token.transferFrom(msg.sender, address(this), delta),
                "transfer unsuccessful"
            );
        }

        ss.balance = amount;
        ss.unlockPeriod = unlockPeriod;
        ss.lockedUntil = 0;
        ss.since = uint64(block.timestamp);
        emit StakeUpdate(msg.sender, amount);
    }

    function requestWithdraw() external {
        StakeState storage ss = _states[msg.sender];
        require(ss.balance > 0);
        updateAccumulatedYield(ss);
        ss.since = uint64(block.timestamp);
        ss.lockedUntil = uint64(block.timestamp + ss.unlockPeriod);
    }

    function withdraw(address to) external {
        StakeState storage ss = _states[msg.sender];
        require(ss.balance > 0, "must have tokens to withdraw");
        require(ss.lockedUntil != 0, "unlock not requested");
        require(ss.lockedUntil < block.timestamp, "still locked");
        updateAccumulatedYield(ss);
        uint128 balance = ss.balance;
        ss.balance = 0;
        ss.unlockPeriod = 0;
        ss.lockedUntil = 0;
        ss.since = 0;
        require(token.transfer(to, balance), "transfer unsuccessful");
        emit StakeUpdate(msg.sender, 0);
    }

    function claimYield() external {
        StakeState storage ss = _states[msg.sender];

        updateAccumulatedYield(ss);
        ss.since = uint64(block.timestamp);
        uint amount = ss.accumulatedYield;
        ss.accumulatedYield = 0;
        token.transfer(msg.sender, amount);
    }
}
