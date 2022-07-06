// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

contract SingleApproveProxy is AccessControl {

    bytes32 public constant HANDLER = keccak256("HANDLER");

    constructor (address _default_admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
    }

    function transferERC20(address _token, address _sender, address _recipient, uint256 _amount) external onlyRole(HANDLER) {
        IERC20(_token).transferFrom(_sender, _recipient, _amount);
    }

    function transferERC721(address _contract, address _sender, address _recipient, uint256 _token) external onlyRole(HANDLER) {
        IERC721(_contract).safeTransferFrom(_sender, _recipient, _token);
    }

    function transferERC1155(address _contract, address _sender, address _recipient, uint256 _token, uint256 _amount) external onlyRole(HANDLER) {
        IERC1155(_contract).safeTransferFrom(_sender, _recipient, _token, _amount, "");
    }

    function transferERC1155Batch(address _contract, address _sender, address _recipient, uint256[] calldata _tokens, uint256[] calldata _amounts) external onlyRole(HANDLER) {
        IERC1155(_contract).safeBatchTransferFrom(_sender, _recipient, _tokens, _amounts, "");
    }

    function selfDestruct(address _sendFundsTo) external onlyRole(DEFAULT_ADMIN_ROLE){
        selfdestruct(payable(_sendFundsTo));
    }
}