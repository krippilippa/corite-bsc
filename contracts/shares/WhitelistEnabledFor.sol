// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Whitelist.sol";

abstract contract WhitelistEnabledFor is Whitelist {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    bool public transferWhiteListRequired;
    bool public claimWhiteListRequired;
    bool public transferBlocked;

    event TransferWhiteListRequired(bool on);
    event ClaimWhiteListRequired(bool on);
    event TransferBlocked(bool on);

    function setTransferWL(bool _on) public onlyRole(ADMIN) {
        transferWhiteListRequired = _on;
        emit TransferWhiteListRequired(_on);
    }

    function setClaimWL(bool _on) public onlyRole(ADMIN) {
        claimWhiteListRequired = _on;
        emit ClaimWhiteListRequired(_on);
    }

    function setTransferBlocked(bool _on) public onlyRole(ADMIN) {
        transferBlocked = _on;
        emit TransferBlocked(_on);
    }
}
