const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");

var collection, testCO, market, owner, buyer, taxAcc, MARKET_ADMIN;

async function setTest721() {
  const Test721 = await ethers.getContractFactory("Test721");
  const test721 = await Test721.deploy(100);
  await test721.deployed();
  return test721;
}

async function setMarketplace() {
  const Market = await ethers.getContractFactory("NFTMarketplace");
  const market = await Market.deploy(taxAcc.address, 10, owner.address);
  await market.deployed();
  return market;
}

describe("Test Marketplace", function () {
  beforeEach(async function () {
    [owner, buyer, taxAcc] = await ethers.getSigners();
    collection = await setTest721();
    testCO = await help.setTestCO();
    market = await setMarketplace();
    await testCO.connect(buyer).approve(market.address, 1000000000);
    MARKET_ADMIN = await market.MARKET_ADMIN();
    await market.grantRole(MARKET_ADMIN, owner.address);
    await market.setValidToken(testCO.address, true);
    await collection.setApprovalForAll(market.address, true);
  });

  it("should add listings", async function () {
    for (let i = 0; i < 10; i++) {
      await market.addListing(collection.address, i, testCO.address, 1000000 + 100000 * i);
    }

    /*    for (let i = 0; i < 10; i += 2) {
      await market.removeListing(collection.address, i);
    } */

    //  console.log((await market.getActiveListings(collection.address)));

    for (let i = 0; i < 10; i++) {
      await market.connect(buyer).buyNFT(collection.address, i, testCO.address, 1000000 + 100000 * i);
    }
  });
});
