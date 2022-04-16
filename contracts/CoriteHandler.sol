//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICorite_ERC1155.sol";
import "libraries/LCorite_ERC1155.sol";

contract CoriteHandler is AccessControl, ReentrancyGuard {
    bytes32 public constant CORITE_ADMIN = keccak256("CORITE_ADMIN");
    bytes32 public constant CORITE_MINTER = keccak256("CORITE_MINTER");
    bytes32 public constant CORITE_CREATOR = keccak256("CORITE_CREATOR");
    bytes32 public constant SERVER_SIGNER = keccak256("SERVER_SIGNER");

    ICorite_ERC1155 public coriteState;
    address private coriteAccount;
    address private refundAccount;
    address public CO;

    struct Stake {
        uint CO;
        bool available;
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

    function registerStakeData(uint _campaignId, uint _start, uint _stop, uint _end, uint _release) external {
        require(coriteState.campaignInfo(_campaignId).supplyCap > 0, "Invalid campaign id");
        require(coriteState.totalSupply(_campaignId) == 0, "Can not register stake after minting shares");
        require(campaignStakeInfo[_campaignId].stakedCOs == 0, "Can not change data after staking has started");
        require(block.timestamp < _start && _start < _stop && _stop < _end && _end < _release, "Invalid timestamp order");
        campaignStakeInfo[_campaignId] = CSInfo({
            start: _start,
            stop: _stop,
            end: _end,
            release: _release,
            stakedCOs: 0,
            soldToNonStakers: 0
        });
    }

    function stake(uint _campaignId, uint _stakeCO) external {
        require(campaignStakeInfo[_campaignId].start < block.timestamp && block.timestamp < campaignStakeInfo[_campaignId].stop,
            "Staking for this campaign is not active");

        IERC20(CO).transferFrom(msg.sender, address(this), _stakeCO);

        stakeInCampaign[msg.sender][_campaignId].CO += _stakeCO;
        stakeInCampaign[msg.sender][_campaignId].available = true;
        campaignStakeInfo[_campaignId].stakedCOs += _stakeCO;
    }

    function releaseStake(uint _campaignId) external nonReentrant() {
        require(campaignStakeInfo[_campaignId].release < block.timestamp, "Can not release before release date");
        require(stakeInCampaign[msg.sender][_campaignId].CO > 0, "Nothing staked");
        IERC20(CO).transfer(msg.sender, stakeInCampaign[msg.sender][_campaignId].CO);
        stakeInCampaign[msg.sender][_campaignId].CO = 0;
    }

    function createCampaign(
        address _owner,
        uint256 _supplyCap,
        uint256 _toBackersCap
    ) external isCORITE_CREATOR {
        coriteState.createCampaign(_owner, _supplyCap, _toBackersCap);
    }

    function buyCampaignShares(
        uint256 _campaignId,
        uint256 _sharesAmount,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes calldata _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(campaignStakeInfo[_campaignId].stop < block.timestamp, "Staking phase is not over");
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

        if(block.timestamp < campaignStakeInfo[_campaignId].end) {
            if(stakeInCampaign[msg.sender][_campaignId].available == true) {
                if(campaignStakeInfo[_campaignId].stakedCOs > coriteState.campaignInfo(_campaignId).toBackersCap) {
                    require(_sharesAmount == (stakeInCampaign[msg.sender][_campaignId].CO * coriteState.campaignInfo(_campaignId).toBackersCap) 
                            / campaignStakeInfo[_campaignId].stakedCOs, "Invalid shares amount");
                } else {
                    require(_sharesAmount == stakeInCampaign[msg.sender][_campaignId].CO, "Invalid shares amount");
                }
                stakeInCampaign[msg.sender][_campaignId].available = false;
            } else {
               logNonStakeCampaignTransfer(_campaignId, _sharesAmount);
            }
        }

        coriteState.incrementNonce(msg.sender);
        if(_tokenAddress == address(0)) {
            require(_tokenAmount == msg.value, "Invalid token amount");
            transferNativeToken(coriteAccount, msg.value);
        } else {
            _checkValidToken(_tokenAddress);
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                coriteAccount,
                _tokenAmount
            );
        }
        coriteState.mintCampaignShares(_campaignId, _sharesAmount, msg.sender);
    }

    function mintCampaignShares(uint256 _campaignId, uint256 _amount, address _to) external isCORITE_MINTER {
        require(campaignStakeInfo[_campaignId].stop < block.timestamp, "Staking phase is not over");
        if(block.timestamp < campaignStakeInfo[_campaignId].end) {
           logNonStakeCampaignTransfer(_campaignId, _amount);
        }
        coriteState.mintCampaignShares(_campaignId, _amount, _to);
    }

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
         if(_tokenAddress == address(0)) {
           transferNativeToken(msg.sender, _tokenAmount);
        } else {
            _checkValidToken(_tokenAddress);
            IERC20(_tokenAddress).transferFrom(refundAccount, msg.sender, _tokenAmount);
        }
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

    function setCampaignCancelled(uint256 _campaignId, bool _cancelled) external isCORITE_ADMIN {
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

    function payToMintNFTs(
        uint256 _collection,
        uint256 _amount,
        address _tokenAddress,
        uint256 _tokenAmount,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
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
        if(_tokenAddress == address(0)) {
            require(_tokenAmount == msg.value, "Invalid token amount");
            transferNativeToken(coriteAccount, msg.value);
        } else {
            _checkValidToken(_tokenAddress);
            IERC20(_tokenAddress).transferFrom(msg.sender, coriteAccount, _tokenAmount);
        }
        _mintCollection(_collection, _amount, msg.sender);
    }

    function mintNFTs(
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

    function adminMintNFTs(uint256 _collection, uint256 _amount, address _to) external isCORITE_MINTER {
        _mintCollection(_collection, _amount, _to);
    }

    function closeCollection(uint256 _collection) external isCORITE_ADMIN {
        coriteState.closeCollection(_collection);
    }

    function setValidToken(address _tokenAddress, bool _valid) external isCORITE_ADMIN {
        validToken[_tokenAddress] = _valid;
        emit ValidTokenEvent(_tokenAddress, _valid);
    }

    function setCoriteAccount(address _account) external isDEFAULT_ADMIN {
        require(_account != refundAccount, "Can not be same as refund account");
        coriteAccount = _account;
    }

    function setRefundAccount(address _account) external isDEFAULT_ADMIN {
        require(_account != coriteAccount, "Can not be same as corite account");
        refundAccount = _account;
    }

    function setCOtoken(address _tokenAddress) external isDEFAULT_ADMIN {
        CO = _tokenAddress;
    }

    function withdrawNativeTokens() external isDEFAULT_ADMIN {
        transferNativeToken(coriteAccount, address(this).balance);
    }

    receive() external payable {}

    function _checkValidToken(address _tokenAddress) internal view {
        require(validToken[_tokenAddress] == true, "Invalid token address");
    }

    function _mintCollection(uint256 _collection, uint256 _amount, address _to) internal {
        if (_amount == 1) {
            coriteState.mintCollectionSingle(_collection, _to);
        } else {
            coriteState.mintCollectionBatch(_collection, _amount, _to);
        }
    }

    function _validateSignature(bytes32 _m, uint8 _v, bytes32 _r, bytes32 _s) internal view {
        require(hasRole(SERVER_SIGNER, ecrecover(_m, _v, _r, _s)), "Invalid server signature");
    }

    function logNonStakeCampaignTransfer(uint _campaignId, uint _amount) internal {
        require( _amount <= coriteState.campaignInfo(_campaignId).toBackersCap 
                - campaignStakeInfo[_campaignId].stakedCOs - campaignStakeInfo[_campaignId].soldToNonStakers, "No available shares to transfer");
        campaignStakeInfo[_campaignId].soldToNonStakers += _amount;
    }

    function transferNativeToken(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to transfer native token");
    }
}
