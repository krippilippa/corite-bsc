// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../CoriteMNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OriginsNFTBurn is AccessControl, Pausable {
    CoriteMNFT immutable OriginsNFT;
    IERC20 immutable COToken;
    address private serverPubKey;

    constructor(
        CoriteMNFT _OriginsNFT,
        IERC20 _COToken,
        address _serverPubKey,
        address _default_admin_role
    ) {
        OriginsNFT = _OriginsNFT;
        COToken = _COToken;
        serverPubKey = _serverPubKey;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function burnAndClaimBacker(
        uint[] calldata _tokenIds,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public whenNotPaused {
        uint prize = burnAndClaim((_tokenIds));

        bytes memory message = abi.encode(msg.sender);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        require(
            ecrecover(
                keccak256(abi.encodePacked(prefix, message)),
                _v,
                _r,
                _s
            ) == serverPubKey,
            "Invalid sign"
        );

        prize *= 10;

        if (prize > 0) COToken.transfer(msg.sender, prize);
    }

    function burnAndClaimNonBacker(uint[] calldata _tokenIds)
        public
        whenNotPaused
    {
        uint prize = burnAndClaim(_tokenIds);
        if (prize > 0) COToken.transfer(msg.sender, prize);
    }

    function burnAndClaim(uint[] calldata _tokenIds) internal returns (uint) {
        uint prize = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(
                OriginsNFT.ownerOf(_tokenIds[i]) == msg.sender,
                "Not NFT Owner"
            );
            uint tokenGroup = _tokenIds[i] / 1000000;
            require(
                tokenGroup == 1000 || tokenGroup == 1001 || tokenGroup == 1032,
                "Wrong token group"
            );

            prize += determinePrize(tokenIdToNum(_tokenIds[i]));
            OriginsNFT.burn(_tokenIds[i]); // burn
        }
        return prize;
    }

    function determinePrize(uint32 num) internal pure returns (uint32) {
        if (num == 0) {
            return 500000000;
        } else if (num < 5) {
            return 100000000;
        } else if (num < 15) {
            return 50000000;
        } else if (num < 65) {
            return 10000000;
        } else if (num < 200) {
            return 5000000;
        } else if (num < 700) {
            return 1000000;
        } else {
            return 0;
        }
    }

    function tokenIdToNum(uint _tokenId) internal pure returns (uint32) {
        uint8 nonce = 0;
        uint32 random_num = uint32(
            bytes4(keccak256(abi.encodePacked(_tokenId, nonce)))
        ) % 1000;
        return random_num;
    }

    function changeServerKey(address _sK) public onlyRole(DEFAULT_ADMIN_ROLE) {
        serverPubKey = _sK;
    }

    function drain(address _to, uint _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        COToken.transfer(_to, _amount);
    }

    function pauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
