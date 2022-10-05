// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/CoriteMNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OriginsNFTBurn is AccessControl, Pausable {
    CoriteMNFT immutable OriginsNFT;
    IERC20 COToken;
    address COAccount;
    address private serverPubKey;

    constructor(
        CoriteMNFT _OriginsNFT,
        IERC20 _COToken,
        address _COAccount,
        address _serverPubKey,
        address _default_admin_role
    ) {
        OriginsNFT = _OriginsNFT;
        COToken = _COToken;
        COAccount = _COAccount;
        serverPubKey = _serverPubKey;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function burnAndClaimBacker(
        uint _tokenId,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public whenNotPaused {
        require(OriginsNFT.ownerOf(_tokenId) == msg.sender, "Not NFT Owner");
        bytes memory message = abi.encode(msg.sender, 1);
        bytes memory prefix = "\x19Ethereum Signed Message:\n64";

        require(
            ecrecover(
                keccak256(abi.encodePacked(prefix, message)),
                _v,
                _r,
                _s
            ) == serverPubKey,
            "Invalid sign"
        );

        uint32 prize = determinePrize(tokenIdToRandom(_tokenId)) * 10;

        OriginsNFT.burn(_tokenId); // burn
        if (prize > 0) COToken.transferFrom(COAccount, msg.sender, prize);
    }

    function burnAndClaimNonBacker(uint _tokenId) public whenNotPaused {
        require(OriginsNFT.ownerOf(_tokenId) == msg.sender, "Not NFT Owner");
        uint32 prize = determinePrize(tokenIdToRandom(_tokenId));

        OriginsNFT.burn(_tokenId); // burn
        if (prize > 0) COToken.transferFrom(COAccount, msg.sender, prize);
    }

    function determinePrize(uint32 num) internal pure returns (uint32) {
        if (num == 1) {
            return 500;
        } else if (num < 5) {
            return 100;
        } else if (num < 15) {
            return 50;
        } else if (num < 65) {
            return 10;
        } else if (num < 200) {
            return 5;
        } else if (num < 700) {
            return 1;
        } else {
            return 0;
        }
    }

    function tokenIdToRandom(uint _tokenId) public view returns (uint32) {
        uint32 random_num = uint32(
            bytes4(keccak256(abi.encodePacked(_tokenId, block.timestamp)))
        ) % 1000;
        return random_num;
    }

    function changeServerKey(address _sK) public onlyRole(DEFAULT_ADMIN_ROLE) {
        serverPubKey = _sK;
    }

    function pauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
