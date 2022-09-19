// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestCO is ERC20 {
    constructor() ERC20("CO TEST", "COtest") {}

    function faucet() external {
        _mint(msg.sender, 1000000000);
    }

    function faucet2(uint amount) external {
        _mint(msg.sender, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
