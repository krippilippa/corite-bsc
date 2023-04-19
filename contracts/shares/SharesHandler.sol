// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IShares.sol";

contract SharesHandler is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant SERVER = keccak256("SERVER");

    address private coriteAccount;
    mapping(address => uint) public internalNonce;

    event Mint(
        address indexed sharesContract,
        address indexed user,
        uint amount
    );

    constructor(address _coriteAccount, address _default_admin_role) {
        coriteAccount = _coriteAccount;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
        _setupRole(ADMIN, _default_admin_role);
    }

    function mintUserPay(
        address _sharesContract,
        uint _amount,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable whenNotPaused {
        bytes memory message = abi.encode(
            msg.sender,
            _sharesContract,
            _amount,
            _tokenAddress,
            _tokenAmount,
            internalNonce[msg.sender],
            address(this)
        );
        require(
            hasRole(
                SERVER,
                ecrecover(
                    keccak256(abi.encodePacked(_prefix, message)),
                    _v,
                    _r,
                    _s
                )
            ),
            "Invalid server signature"
        );

        internalNonce[msg.sender]++;
        _transferTokens(_tokenAddress, _tokenAmount);
        _mint(_sharesContract, msg.sender, _amount);
    }

    function mintForUser(
        address _sharesContract,
        address[] calldata _to,
        uint _amount
    ) external onlyRole(ADMIN) {
        uint length = _to.length;
        for (uint i = 0; i < length; i++) {
            _mint(_sharesContract, _to[i], _amount);
        }
    }

    function _mint(
        address _sharesContract,
        address _to,
        uint _amount
    ) internal {
        IShares(_sharesContract).mint(_to, _amount);
        emit Mint(_sharesContract, _to, _amount);
    }

    function setCoriteAccount(address _account) external onlyRole(ADMIN) {
        coriteAccount = _account;
    }

    function pauseHandler() external onlyRole(ADMIN) {
        _pause();
    }

    function unpauseHandler() external onlyRole(ADMIN) {
        _unpause();
    }

    function _transferNativeToken(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to transfer native token");
    }

    function _transferTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal {
        if (_tokenAddress == address(0)) {
            require(_tokenAmount == msg.value, "Invalid token amount");
            _transferNativeToken(coriteAccount, msg.value);
        } else {
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                coriteAccount,
                _tokenAmount
            );
        }
    }
}
