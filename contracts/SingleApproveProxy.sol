// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SingleApproveProxy is AccessControl {

    bytes32 public constant HANDLER = keccak256("HANDLER");

    mapping (address => bool) approvedTokens;

    event TokenApproved(address token, bool approved);

    constructor (address _default_admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
    }

    function transferFrom(address _token, address _sender, address _recipient, uint256 _amount) external payable onlyRole(HANDLER) {
        require(approvedTokens[_token], "ERC20 token not approved as payment");
        IERC20(_token).transferFrom(_sender, _recipient, _amount);
    }

    function setTokenApproved(address _token, bool _approved) external onlyRole(DEFAULT_ADMIN_ROLE){
        approvedTokens[_token] = _approved;
        emit TokenApproved(_token, _approved);
    }

    function selfDestruct(address _kill) external onlyRole(DEFAULT_ADMIN_ROLE){
        selfdestruct(payable(_kill));
    }
}