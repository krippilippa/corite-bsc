const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");

var testCO, CNR, owner, buyer, taxAcc, MINTER, BURNER, REDEEMER, ADMIN;

async function setMoments(CNR) {
  const Moments = await ethers.getContractFactory("Moments");
  const moments = await Moments.deploy(CNR.address, owner.address);
  await moments.deployed();
  return moments;
}

async function setMomentsHandler(moments) {
  const MomentsHandler = await ethers.getContractFactory("MomentsHandler");
  const momentsHandler = await MomentsHandler.deploy(moments.address, owner.address);
  await momentsHandler.deployed();
  return momentsHandler;
}

describe("Test Moments", function () {
  beforeEach(async function () {
    [owner, buyer, taxAcc] = await ethers.getSigners();
    CNR = await help.setCNR();
    moments = await setMoments(CNR);
    momentsHandler = await setMomentsHandler(moments);
    MINTER = await moments.MINTER();
    BURNER = await moments.BURNER();
    REDEEMER = await moments.REDEEMER();
    ADMIN = await momentsHandler.ADMIN();
    await moments.grantRole(MINTER, momentsHandler.address);
    await moments.grantRole(BURNER, momentsHandler.address);
    await moments.grantRole(REDEEMER, momentsHandler.address);
    await momentsHandler.grantRole(ADMIN, owner.address);
    testCO = await help.setTestCO();
    await momentsHandler.setCoriteAccount(taxAcc.address);
    await momentsHandler.setValidToken(testCO.address, true);
    await testCO.connect(buyer).approve(momentsHandler.address, 1000000000);
  });

  it("should claim NFT", async function () {
    await momentsHandler.createGroup(1, 1000, 1);
    await momentsHandler.setOpenMinting(1, true);
    await momentsHandler.connect(buyer).claimNFT(1);
    expect(await moments.ownerOf(1000000)).to.be.equal(buyer.address);
    await momentsHandler.setRedeemed(1000000, 100);
    console.log(await moments.getRedeemedList(1000000, [99, 100, 101]));
  });

  it("should claim NFT with sig", async function () {
    await momentsHandler.createGroup(1, 1000, 1);
    await momentsHandler.setOpenMinting(1, true);
    await momentsHandler.connect(buyer).claimNFT(1);
    expect(await moments.ownerOf(1000000)).to.be.equal(buyer.address);
  });
});
