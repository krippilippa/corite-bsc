const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");

var collection, campaign, testCO, market, owner, owner2, buyer, taxAcc, MARKET_ADMIN, HANDLER, proxy, marketState;

async function setTest721() {
  const Test721 = await ethers.getContractFactory("Test721");
  const test721 = await Test721.deploy(100);
  await test721.deployed();
  return test721;
}

async function setTest1155() {
  const Test721 = await ethers.getContractFactory("Test1155");
  const test721 = await Test721.deploy(10, 100, [owner2.address]);
  await test721.deployed();
  return test721;
}

async function setMarketplace(proxy, marketState) {
  const Market = await ethers.getContractFactory("Marketplace");
  const market = await Market.deploy(proxy.address, marketState.address, owner.address);
  await market.deployed();
  return market;
}

async function setMarketState() {
  const Market = await ethers.getContractFactory("MarketState");
  const market = await Market.deploy(owner.address);
  await market.deployed();
  return market;
}

describe("Test Marketplace", function () {
  beforeEach(async function () {
    [owner, owner2, buyer, taxAcc] = await ethers.getSigners();
    collection = await setTest721();
    campaign = await setTest1155();
    testCO = await help.setTestCO();
    proxy = await help.setSingleApproveProxy(owner);
    marketState = await setMarketState();
    market = await setMarketplace(proxy, marketState);
    await testCO.connect(buyer).approve(proxy.address, 1000000000);
    MARKET_ADMIN = await market.MARKET_ADMIN();
    HANDLER = await marketState.HANDLER();
    await marketState.grantRole(HANDLER, market.address);
    await proxy.grantRole(HANDLER, market.address);
    await market.grantRole(MARKET_ADMIN, owner.address);
    await market.setValidToken(testCO.address, true);
    await market.setValidToken("0x0000000000000000000000000000000000000000", true);
    await collection.setApprovalForAll(proxy.address, true);
    await campaign.setApprovalForAll(proxy.address, true);
    await campaign.connect(owner2).setApprovalForAll(proxy.address, true);
    await market.setValidContract(collection.address, true);
    await market.setValidContract(campaign.address, true);
  });

  it("should add listings", async function () {
    for (let i = 0; i < 10; i++) {
      await market.addListing(collection.address, i, "0x0000000000000000000000000000000000000000", 1000000 + 100000 * i);
    }
    for (let i = 10; i < 20; i++) {
      await market.addListing(collection.address, i, testCO.address, 1000000 + 100000 * i);
    }
    console.log((await marketState.getListing(collection.address, 2)));
    for (let i = 0; i < 10; i++) {
      await market.addCampaignListing(campaign.address, i, i * 10 + 10, testCO.address, 1000000 + 100000 * i);
      await market
        .connect(owner2)
        .addCampaignListing(campaign.address, i, i * 10 + 10, testCO.address, 1000000 + 100000 * i);
      //  console.log((await marketState.getActiveCampaignListings(campaign.address, i, 0, 10)));
        //  console.log((await marketState.getActiveCampaignListings(campaign.address, i, 0, 10)).length);
    }

    await market.connect(buyer).buyNFT(collection.address, 2, "0x0000000000000000000000000000000000000000", 1000000 + 100000 * 2, {value: 1000000 + 100000 * 2,});
    await market.connect(buyer).buyNFT(collection.address, 12, testCO.address, 1000000 + 100000 * 12);

    // console.log((await marketState.getCampaignListing(campaign.address, 1, buyer.address)));

    // console.log(await marketState.getActiveCampaignListings(campaign.address, 5, 0, 6));

    // for (let i = 0; i < 10; i += 2) {
    //   console.log(i);
    //   await market.removeListing(collection.address, i);
    // }

    // for (let i = 1; i < 10; i += 2) {
    //    console.log((await marketState.getActiveCampaignListings(campaign.address, i)).length);
    //   console.log(await marketState.campaignListingIndex(campaign.address, i, owner.address));
    //   await market.removeCampaignListing(campaign.address, i, owner2.address);
    // }

    //  console.log((await market.getActiveListings(collection.address)));

    // console.log(await marketState.getActiveListings(collection.address));
    // for (let i = 1; i <= 10; i += 2) {
    //   await market.connect(buyer).buyNFT(collection.address, i, testCO.address, 1000000 + 100000 * i);
    // }

    // for (let i = 0; i < 10; i += 2) {
    //   await market
    //     .connect(buyer)
    //     .buyCampaignShares(campaign.address, i, owner2.address, i * 10 + 10, testCO.address, 1000000 + 100000 * i);
    // }
  });
});
