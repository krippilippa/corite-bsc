//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICorite_ERC1155.sol";
import "../interfaces/INonceCounter.sol";

contract CoriteHandler is AccessControl {
    bytes32 public constant CORITE_ADMIN = keccak256("CORITE_ADMIN");
    bytes32 public constant CORITE_MINTER = keccak256("CORITE_MINTER");
    bytes32 public constant CORITE_CREATOR = keccak256("CORITE_CREATOR");
    bytes32 public constant SERVER_SIGNER = keccak256("SERVER_SIGNER");
    ICorite_ERC1155 public state;
    INonceCounter public nonceCounter;
    address private coriteAccount;

    mapping(address => bool) public validToken;

    event ValidTokenEvent(address indexed tokenAddress, bool valid);

    constructor(
        ICorite_ERC1155 _state,
        INonceCounter _nonceCounter,
        address _defaultAdmin
    ) {
        state = _state;
        nonceCounter = _nonceCounter;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    modifier isDEFAULT_ADMIN() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "DEFAULT_ADMIN_ROLE role required"
        );
        _;
    }

    modifier isCORITE_ADMIN() {
        require(
            hasRole(CORITE_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CORITE_ADMIN role required"
        );
        _;
    }

    modifier isCORITE_MINTER() {
        require(
            hasRole(CORITE_MINTER, msg.sender) ||
                hasRole(CORITE_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CORITE_MINTER role required"
        );
        _;
    }

    modifier isCORITE_CREATOR() {
        require(
            hasRole(CORITE_CREATOR, msg.sender) ||
                hasRole(CORITE_MINTER, msg.sender) ||
                hasRole(CORITE_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CORITE_CREATOR role required"
        );
        _;
    }

    function createCampaign(
        address _owner,
        uint256 _supplyCap,
        uint256 _toBackersCap
    ) external isCORITE_CREATOR {
        state.createCampaign(_owner, _supplyCap, _toBackersCap);
    }

    function buyCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes memory prefix = "\x19Ethereum Signed Message:\n168";
        _checkValidToken(_tokenAddress);
        bytes32 m = keccak256(
            abi.encodePacked(
                prefix,
                msg.sender,
                _campaignId,
                _sharesAmount,
                _tokenAddress,
                _tokenAmount,
                nonceCounter.currentNonce(msg.sender)
            )
        );
        _validateSignature(m, _v, _r, _s);
        nonceCounter.incrementNonce(msg.sender);
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            coriteAccount,
            _tokenAmount
        );
        state.mintCampaignShares(_campaignId, _sharesAmount, msg.sender);
    }

    function mintCampaignShares(
        uint256 _campaignId,
        uint256 _amount,
        address _to
    ) external isCORITE_MINTER {
        state.mintCampaignShares(_campaignId, _amount, _to);
    }

    function refundCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _checkValidToken(_tokenAddress);
        bytes memory prefix = "\x19Ethereum Signed Message:\n168";
        bytes32 m = keccak256(
            abi.encodePacked(
                prefix,
                msg.sender,
                _tokenAddress,
                _tokenAmount,
                _campaignId,
                _sharesAmount,
                nonceCounter.currentNonce(msg.sender)
            )
        );
        _validateSignature(m, _v, _r, _s);
        nonceCounter.incrementNonce(msg.sender);

        state.burnToken(_campaignId, _sharesAmount, msg.sender);
        IERC20(_tokenAddress).transferFrom(
            coriteAccount,
            msg.sender,
            _tokenAmount
        );
    }

    function burnCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes memory prefix = "\x19Ethereum Signed Message:\n116";
        bytes32 m = keccak256(
            abi.encodePacked(
                prefix,
                msg.sender,
                _campaignId,
                _sharesAmount,
                nonceCounter.currentNonce(msg.sender)
            )
        );
        _validateSignature(m, _v, _r, _s);
        nonceCounter.incrementNonce(msg.sender);

        state.burnToken(_campaignId, _sharesAmount, msg.sender);
    }

    function closeCampaign(uint256 _campaignId) external isCORITE_ADMIN {
        state.closeCampaign(_campaignId);
    }

    function setCampaignCancelled(uint256 _campaignId, bool _cancelled)
        external
        isCORITE_ADMIN
    {
        state.setCampaignCancelled(_campaignId, _cancelled);
    }

    function createCollection(
        address _owner,
        uint256 _totalSupply,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 m = keccak256(
            abi.encodePacked(
                _prefix,
                _owner,
                _totalSupply,
                state.getCollectionCount(_owner)
            )
        );
        _validateSignature(m, _v, _r, _s);
        state.createCollection(_owner, _totalSupply);
    }

    function paidCollectionMint(
        uint256 _collection,
        uint256 _amount,
        uint256 _price,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(msg.value == _price, "Invalid msg value");
        bytes32 m = keccak256(
            abi.encodePacked(
                _prefix,
                msg.sender,
                _collection,
                _amount,
                _price,
                nonceCounter.currentNonce(msg.sender)
            )
        );
        _validateSignature(m, _v, _r, _s);
        nonceCounter.incrementNonce(msg.sender);
        (bool sent, ) = coriteAccount.call{value: msg.value}("");
        require(sent, "Failed to send native token");
        _mintCollection(_collection, _amount, msg.sender);
    }

    function paidCollectionMint(
        uint256 _collection,
        uint256 _amount,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _checkValidToken(_tokenAddress);
        bytes32 m = keccak256(
            abi.encodePacked(
                _prefix,
                msg.sender,
                _collection,
                _amount,
                _tokenAddress,
                _tokenAmount,
                nonceCounter.currentNonce(msg.sender)
            )
        );
        _validateSignature(m, _v, _r, _s);
        nonceCounter.incrementNonce(msg.sender);
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            coriteAccount,
            _tokenAmount
        );
        _mintCollection(_collection, _amount, msg.sender);
    }

    function collectionMint(
        uint256 _collection,
        uint256 _amount,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        bytes32 m = keccak256(
            abi.encodePacked(
                _prefix,
                msg.sender,
                _collection,
                _amount,
                nonceCounter.currentNonce(msg.sender)
            )
        );
        _validateSignature(m, _v, _r, _s);
        nonceCounter.incrementNonce(msg.sender);
        _mintCollection(_collection, _amount, msg.sender);
    }

    function adminCollectionMint(
        uint256 _collection,
        uint256 _amount,
        address _to
    ) external isCORITE_MINTER {
        _mintCollection(_collection, _amount, _to);
    }

    function closeCollection(uint256 _collection) external isCORITE_ADMIN {
        state.closeCollection(_collection);
    }

    function setValidToken(address _tokenAddress, bool _valid)
        external
        isCORITE_ADMIN
    {
        validToken[_tokenAddress] = _valid;
        emit ValidTokenEvent(_tokenAddress, _valid);
    }

    function setCoriteAccount(address _account) external isDEFAULT_ADMIN {
        coriteAccount = _account;
    }

    function _checkValidToken(address _tokenAddress) internal view {
        require(validToken[_tokenAddress] == true, "Invalid token address");
    }

    function _mintCollection(
        uint256 _collection,
        uint256 _amount,
        address _to
    ) internal {
        if (_amount == 1) {
            state.mintCollectionSingle(_collection, _to);
        } else {
            state.mintCollectionBatch(_collection, _amount, _to);
        }
    }

    function _validateSignature(
        bytes32 _m,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {
        require(
            hasRole(SERVER_SIGNER, ecrecover(_m, _v, _r, _s)),
            "Invalid server signature"
        );
    }
}
