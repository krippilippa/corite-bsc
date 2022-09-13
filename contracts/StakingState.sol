// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "../interfaces/IAsset.sol";
// import "../interfaces/ICNR.sol";

contract StakingState is AccessControl {

    // ICNR CNR; 

    bytes32 public constant ASSET_PROVIDER = keccak256("ADMIN");
    
    //check addresses staked amount
    mapping(address => uint) stakedAmount;
    //check staked address
    mapping(address => bool) stakedAddress;
    
    IERC20 token; 

    event tokensStaked(address from, uint amount);
    event tokensUnstaked(address to, uint amount);

    // both should be editable by admin
    uint minStakeAmount = 100;
    uint maxStakeAmount = 20000;

    // tx timer for unstaking. 1 day 84600 seconds, 86400000 Milliseconds. 2 weeks = 1209600 Seconds, 1209600000 milliseconds 
    uint unstakingTime;
    
    constructor (address _default_admin_role) {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }
    // should we have a certain staking lock up time? ex 30, 90, 180 days etc
    function stake(uint _from, int _token, bool staked) external {

    }
}