//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICorite_ERC1155.sol";
import "libraries/LCorite_ERC1155.sol";

contract CoriteHandler is AccessControl {
    bytes32 public constant CORITE_ADMIN = keccak256("CORITE_ADMIN");
    bytes32 public constant CORITE_MINTER = keccak256("CORITE_MINTER");
    bytes32 public constant CORITE_CREATOR = keccak256("CORITE_CREATOR");
    bytes32 public constant SERVER_SIGNER = keccak256("SERVER_SIGNER");

    ICorite_ERC1155 public coriteState;
    address private coriteAccount;
    address public CO;

    struct Stake {
        uint CO;
        bool used;
    }

    struct CSInfo{
        uint start;
        uint stop;
        uint end;
        uint release;
        uint stakedCOs;
        uint soldToNonStakers;
    }

    mapping(address => bool) public validToken;
    mapping(address => mapping(uint => Stake)) public stakeInCampaign;
    mapping(uint => CSInfo) public campaignStakeInfo; 

    event ValidTokenEvent(address indexed tokenAddress, bool valid);

    constructor(ICorite_ERC1155 _coriteState, address _defaultAdmin) {
        coriteState = _coriteState;
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

    function stake(uint _campaignId, uint _stakeCO) public {
        require(campaignStakeInfo[_campaignId].start < block.timestamp && block.timestamp < campaignStakeInfo[_campaignId].stop,
            "Staking for this campaign is not active");

        IERC20(CO).transferFrom(msg.sender, address(this), _stakeCO);

        stakeInCampaign[msg.sender][_campaignId].CO = stakeInCampaign[msg.sender][_campaignId].CO + _stakeCO;
        campaignStakeInfo[_campaignId].stakedCOs = campaignStakeInfo[_campaignId].stakedCOs + _stakeCO;
    }

    function releaseStake(uint _campaignId) public {
        require(campaignStakeInfo[_campaignId].release > block.timestamp, "Can not release before release date");
        require(stakeInCampaign[msg.sender][_campaignId].CO > 0, "Nothing staked");
        IERC20(CO).transfer(msg.sender, stakeInCampaign[msg.sender][_campaignId].CO);
    }

    function createCampaign(
        address _owner,
        uint256 _supplyCap,
        uint256 _toBackersCap
    ) external isCORITE_CREATOR {
        coriteState.createCampaign(_owner, _supplyCap, _toBackersCap);
    }

    // function buyCampaignSharesNative(
    //     uint256 _campaignId,
    //     uint256 _sharesAmount,
    //     bytes calldata _prefix,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external payable {
    //     bytes memory message = abi.encode(
    //         msg.sender,
    //         _campaignId,
    //         _sharesAmount,
    //         msg.value,
    //         coriteState.currentNonce(msg.sender)
    //     );

    //     bytes32 m = keccak256(abi.encodePacked(_prefix, message));
    //     _validateSignature(m, _v, _r, _s);
    //     coriteState.incrementNonce(msg.sender);
    //     transferNativeToken(coriteAccount, msg.value);
    //     coriteState.mintCampaignShares(_campaignId, _sharesAmount, msg.sender);
    // }

    function buyCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _checkValidToken(_tokenAddress);
        bytes memory message = abi.encode(
            msg.sender,
            _campaignId,
            _sharesAmount,
            _tokenAddress,
            _tokenAmount,
            coriteState.currentNonce(msg.sender)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);
        coriteState.incrementNonce(msg.sender);
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            coriteAccount,
            _tokenAmount
        );
        coriteState.mintCampaignShares(_campaignId, _sharesAmount, msg.sender);
    }

    function mintCampaignShares(uint256 _campaignId, uint256 _amount, address _to) external isCORITE_MINTER {
        coriteState.mintCampaignShares(_campaignId, _amount, _to);
    }

    // function refundCampaignSharesNative(
    //     uint256 _campaignId,
    //     uint256 _sharesAmount,
    //     uint256 _refundAmount,
    //     bytes calldata _prefix,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external {
    //     bytes memory message = abi.encode(
    //         msg.sender,
    //         _refundAmount,
    //         _campaignId,
    //         _sharesAmount,
    //         coriteState.currentNonce(msg.sender)
    //     );
    //     bytes32 m = keccak256(abi.encodePacked(_prefix, message));
    //     _validateSignature(m, _v, _r, _s);

    //     coriteState.incrementNonce(msg.sender);
    //     coriteState.burnToken(_campaignId, _sharesAmount, msg.sender);
    //     transferNativeToken(msg.sender, _refundAmount);
    // }

    function refundCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _checkValidToken(_tokenAddress);
        bytes memory message = abi.encode(
            msg.sender,
            _tokenAddress,
            _tokenAmount,
            _campaignId,
            _sharesAmount,
            coriteState.currentNonce(msg.sender)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);
        coriteState.incrementNonce(msg.sender);

        coriteState.burnToken(_campaignId, _sharesAmount, msg.sender);
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

    function burnCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes memory message = abi.encode(
            msg.sender,
            _campaignId,
            _sharesAmount,
            coriteState.currentNonce(msg.sender)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);

        coriteState.incrementNonce(msg.sender);
        coriteState.burnToken(_campaignId, _sharesAmount, msg.sender);
    }

    function closeCampaign(uint256 _campaignId) external isCORITE_ADMIN {
        coriteState.closeCampaign(_campaignId);
    }

    function setCampaignCancelled(uint256 _campaignId, bool _cancelled)
        external
        isCORITE_ADMIN
    {
        coriteState.setCampaignCancelled(_campaignId, _cancelled);
    }

    function createCollection(
        address _owner,
        uint256 _totalSupply,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes memory message = abi.encode(
            _owner,
            _totalSupply,
            coriteState.getCollectionCount(_owner)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);
        coriteState.createCollection(_owner, _totalSupply);
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
        bytes memory message = abi.encode(
            msg.sender,
            _collection,
            _amount,
            _price,
            coriteState.currentNonce(msg.sender)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);

        coriteState.incrementNonce(msg.sender);
        transferNativeToken(coriteAccount, msg.value);
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
        bytes memory message = abi.encode(
            msg.sender,
            _collection,
            _amount,
            _tokenAddress,
            _tokenAmount,
            coriteState.currentNonce(msg.sender)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);

        coriteState.incrementNonce(msg.sender);
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
        bytes memory message = abi.encode(
            msg.sender,
            _collection,
            _amount,
            coriteState.currentNonce(msg.sender)
        );
        bytes32 m = keccak256(abi.encodePacked(_prefix, message));
        _validateSignature(m, _v, _r, _s);
        coriteState.incrementNonce(msg.sender);
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
        coriteState.closeCollection(_collection);
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

    function withdrawUnusedTokens(address _tokenAddress)
        external
        isDEFAULT_ADMIN
    {
        if (_tokenAddress != address(0)) {
            uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
            IERC20(_tokenAddress).transfer(coriteAccount, balance);
        } else {
            transferNativeToken(coriteAccount, address(this).balance);
        }
    }

    receive() external payable {}

    function _checkValidToken(address _tokenAddress) internal view {
        require(validToken[_tokenAddress] == true, "Invalid token address");
    }

    function _mintCollection(
        uint256 _collection,
        uint256 _amount,
        address _to
    ) internal {
        if (_amount == 1) {
            coriteState.mintCollectionSingle(_collection, _to);
        } else {
            coriteState.mintCollectionBatch(_collection, _amount, _to);
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

    function transferNativeToken(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to transfer native token");
    }
}
