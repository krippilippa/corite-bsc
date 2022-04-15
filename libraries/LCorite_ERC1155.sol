// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LCorite_ERC1155 {

    struct Campaign {
        address owner;

        uint supplyCap;
        uint toBackersCap;
        bool hasMintedExcess;

        bool closed;
        bool cancelled;
    }

    struct Collection {
        address owner;

        uint maxTokenId;
        uint latestTokenId;

        bool closed;
    }
}
