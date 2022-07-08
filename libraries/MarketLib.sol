 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



library MarketLib {

    struct Listing {
        uint tokenId;
        address owner;
        address currency;
        uint price;
    }
    
    struct ValidContract {
        uint feeRate;
        address feeAccount;
        bool valid;
    }

    struct CampaignListing {
        address owner;
        address currency;
        uint unitPrice;
        uint amount;
    }
}