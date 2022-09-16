/**
 *Submitted for verification at Etherscan.io on 2020-11-09
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract COStake is AccessControl, ReentrancyGuard {
    struct StakeState {
        uint64 balance;
        uint64 unlockPeriod; // time it takes from requesting withdraw to being able to withdraw
        uint64 lockedUntil; // 0 if withdraw is not requested
        uint64 since;
        uint128 accumulated; // token-days staked
        uint128 accumulatedStrict; // token-days staked sans withdraw periods
        uint accumulatedYield;
    }

    event StakeUpdate(address indexed from, uint64 balance);
    event WithdrawRequest(address indexed from, uint64 until);

    mapping(address => StakeState) private _states;

    uint[] private yieldRates;
    uint[] private yieldRateDates;

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

    function getAccumulated(address account)
        external
        view
        returns (uint128, uint128)
    {
        StakeState storage ss = _states[account];
        return (ss.accumulated, ss.accumulatedStrict);
    }

    function calculateAccumulated(StakeState storage ss)
        internal
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        uint sum = ss.accumulated;
        uint sumStrict = ss.accumulatedStrict;
        uint yield = ss.accumulatedYield;
        if (ss.balance > 0) {
            uint256 until = block.timestamp;
            if (ss.lockedUntil > 0 && ss.lockedUntil < block.timestamp) {
                until = ss.lockedUntil;
            }
            if (until > ss.since) {
                uint delta = uint128(
                    (uint256(ss.balance) * (until - ss.since)) / 86400
                );
                sum += delta;
                if (ss.lockedUntil == 0) {
                    sumStrict += delta;
                    uint last;
                    for (uint i = 0; i < yieldRates.length; i++) {
                        if (yieldRateDates[i] < ss.since) {
                            continue;
                        } else {
                            last = yieldRateDates[i - 1] < ss.since
                                ? ss.since
                                : yieldRateDates[i - 1];
                            delta =
                                ((ss.balance * (yieldRateDates[i] - last)) /
                                    86400) /
                                yieldRates[i - 1];
                            yield += delta;
                        }
                    }
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
        return (sum, sumStrict, yield);
    }

    function estimateAccumulated(address account)
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        StakeState storage ss = _states[account];
        return calculateAccumulated(ss);
    }

    function updateAccumulated(StakeState storage ss) private {
        (
            uint _accumulated,
            uint _accumulatedStrict,
            uint _accumulatedYield
        ) = calculateAccumulated(ss);
        ss.accumulated = uint128(_accumulated);
        ss.accumulatedStrict = uint128(_accumulatedStrict);
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

        updateAccumulated(ss);

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
        updateAccumulated(ss);
        ss.since = uint64(block.timestamp);
        ss.lockedUntil = uint64(block.timestamp + ss.unlockPeriod);
    }

    function withdraw(address to) external {
        StakeState storage ss = _states[msg.sender];
        require(ss.balance > 0, "must have tokens to withdraw");
        require(ss.lockedUntil != 0, "unlock not requested");
        require(ss.lockedUntil < block.timestamp, "still locked");
        updateAccumulated(ss);
        uint128 balance = ss.balance;
        ss.balance = 0;
        ss.unlockPeriod = 0;
        ss.lockedUntil = 0;
        ss.since = 0;
        require(token.transfer(to, balance), "transfer unsuccessful");
        emit StakeUpdate(msg.sender, 0);
    }

    function claimYield() external nonReentrant {
        StakeState storage ss = _states[msg.sender];

        updateAccumulated(ss);
        ss.since = uint64(block.timestamp);
        token.transfer(msg.sender, ss.accumulatedYield);
        ss.accumulatedYield = 0;
    }
}
