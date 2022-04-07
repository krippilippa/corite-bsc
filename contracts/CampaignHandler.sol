//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICorite_ERC1155.sol";
import "../interfaces/INonceCounter.sol";

contract CampaignHandler is AccessControl {
    bytes32 public constant CAMPAIGN_ADMIN = keccak256("CAMPAIGN_ADMIN");
    bytes32 public constant CAMPAIGN_MINTER = keccak256("CAMPAIGN_MINTER");
    bytes32 public constant CAMPAIGN_CREATOR = keccak256("CAMPAIGN_CREATOR");
    ICorite_ERC1155 public campaigns;
    INonceCounter public nonceCounter;
    address private coriteAccount;
    address private serverPubKey;

    mapping(address => bool) public validToken;

    event ValidTokenEvent(address indexed tokenAddress, bool valid);

    constructor(
        ICorite_ERC1155 _campaigns,
        INonceCounter _nonceCounter,
        address _defaultAdmin
    ) {
        campaigns = _campaigns;
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

    modifier isCAMPAIGN_ADMIN() {
        require(
            hasRole(CAMPAIGN_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CAMPAIGN_ADMIN role required"
        );
        _;
    }

    modifier isCAMPAIGN_MINTER() {
        require(
            hasRole(CAMPAIGN_MINTER, msg.sender) ||
                hasRole(CAMPAIGN_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CAMPAIGN_MINTER role required"
        );
        _;
    }

    modifier isCAMPAIGN_CREATOR() {
        require(
            hasRole(CAMPAIGN_CREATOR, msg.sender) ||
                hasRole(CAMPAIGN_MINTER, msg.sender) ||
                hasRole(CAMPAIGN_ADMIN, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "CAMPAIGN_CREATOR role required"
        );
        _;
    }

    function createCampaign(
        address _owner,
        uint256 _supplyCap,
        uint256 _toBackersCap
    ) external isCAMPAIGN_CREATOR {
        campaigns.createCampaign(_owner, _supplyCap, _toBackersCap);
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
        require(validToken[_tokenAddress] == true, "Invalid token address");
        bytes memory prefix = "\x19Ethereum Signed Message:\n168";
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
        campaigns.mintCampaignShares(_campaignId, _sharesAmount, msg.sender);
    }

    function mintCampaignShares(
        uint256 _campaignId,
        uint256 _amount,
        address _to
    ) external isCAMPAIGN_MINTER {
        campaigns.mintCampaignShares(_campaignId, _amount, _to);
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
        require(validToken[_tokenAddress] == true, "Invalid token address");
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

        campaigns.burnToken(_campaignId, _sharesAmount, msg.sender);
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

        campaigns.burnToken(_campaignId, _sharesAmount, msg.sender);
    }

    function closeCampaign(uint256 _campaignId) external isCAMPAIGN_ADMIN {
        campaigns.closeCampaign(_campaignId);
    }

    function setCampaignCancelled(uint256 _campaignId, bool _cancelled)
        external
        isCAMPAIGN_ADMIN
    {
        campaigns.setCampaignCancelled(_campaignId, _cancelled);
    }

    function setValidToken(address _tokenAddress, bool _valid)
        external
        isCAMPAIGN_ADMIN
    {
        validToken[_tokenAddress] = _valid;
        emit ValidTokenEvent(_tokenAddress, _valid);
    }

    function setServerKey(address _serverPubKey) external isCAMPAIGN_ADMIN {
        serverPubKey = _serverPubKey;
    }

    function setCoriteAccount(address _account) external isDEFAULT_ADMIN {
        coriteAccount = _account;
    }

    function _validateSignature(
        bytes32 _m,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {
        require(
            ecrecover(_m, _v, _r, _s) == serverPubKey,
            "Invalid server signature"
        );
    }
}
