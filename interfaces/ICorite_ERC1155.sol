// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "libraries/LCorite_ERC1155.sol";

interface ICorite_ERC1155 {

    function ownedCollections(address _owner)
        external
        view
        returns (uint256[] memory);

    function ownedCampaigns(address _owner)
        external
        view
        returns (uint256[] memory);

    function currentNonce(address _user) external returns (uint256);

    function createCampaign(
        address _owner,
        uint256 _supplyCap,
        uint256 _toBackersCap
    ) external returns (uint256);

    function closeCampaign(uint256 _campaign) external;

    function mintCampaignShares(
        uint256 _campaign,
        uint256 _amount,
        address _to
    ) external;

    function setCampaignCancelled(uint256 _campaign, bool _cancelled) external;

    function createCollection(address _owner, uint256 _totalSupply)
        external
        returns (uint256);

    function mintCollectionBatch(
        uint256 _collection,
        uint256 _amount,
        address _to
    ) external;

    function mintCollectionSingle(uint256 _collection, address _to) external;

    function closeCollection(uint256 _collection) external;

    function burnToken(
        uint256 _fullTokenId,
        uint256 _amount,
        address _from
    ) external;

    function getCampaignCount(address _owner) external view returns (uint256);

    function getCollectionCount(address _owner) external view returns (uint256);

    function incrementNonce(address _user) external;

    function campaignInfo(uint _campaignId) external view returns(LCorite_ERC1155.Campaign memory);

    function collectionInfo(uint _campaignId) external view returns(LCorite_ERC1155.Collection memory);

}
