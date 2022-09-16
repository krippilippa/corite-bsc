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

    address public yieldBank;

    event StakeUpdate(address indexed from, uint64 balance);
    event WithdrawRequest(address indexed from, uint64 until);

    mapping(address => StakeState) private _states;

    // denotes a change in yield
    struct YieldPoint {
        uint yieldRate; // New yield rate
        uint timestamp; // timestamp of change
    }
    // Records the changes in the yieldrate
    YieldPoint[] yieldTimeline;

    IERC20 private token;

    constructor(
        IERC20 _token,
        uint initialRate,
        address _yieldBank
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = _token;
        yieldTimeline.push(YieldPoint(initialRate, block.timestamp));
        yieldBank = _yieldBank;
    }

    function setYieldBank(address _yieldBank)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        yieldBank = _yieldBank;
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

    function setYieldRate(uint _yieldRate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_yieldRate > 0, "Yield rate must be greater than 0");
        yieldTimeline.push(YieldPoint(_yieldRate, block.timestamp));
    }

    function pauseYield() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // Since delta is divided by yieldrate, an "infinite" yieldrate sets the delta to 0 - aka 0% yield
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
                    for (uint i = 0; i < yieldTimeline.length; i++) {
                        // find the earliest applicable yield rate based on ss.since and loop through all the
                        // following yieldTimeline/dates
                        if (yieldTimeline[i].timestamp < ss.since) {
                            continue;
                        } else {
                            last = yieldTimeline[i - 1].timestamp < ss.since
                                ? ss.since
                                : yieldTimeline[i - 1].timestamp;
                            delta =
                                ((ss.balance *
                                    (yieldTimeline[i].timestamp - last)) /
                                    86400) /
                                yieldTimeline[i - 1].yieldRate; // calculate the delta for a specific yield period
                            yield += delta;
                        }
                    }
                    // finally calculate the delta of latest yield rate up to current date
                    last = yieldTimeline[yieldTimeline.length - 1].timestamp <
                        ss.since
                        ? ss.since
                        : yieldTimeline[yieldTimeline.length - 1].timestamp;
                    delta =
                        ((ss.balance * (until - last)) / 86400) /
                        yieldTimeline[yieldTimeline.length - 1].yieldRate;
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
        token.transferFrom(yieldBank, msg.sender, amount);
    }
}
