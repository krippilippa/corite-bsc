const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");
const firstCampaignId =
  "100000000000000000000000000000000000000000000000000000000000000000001";

var owner, admin, artist, backer, server;

describe("Test campaigns", function () {
  var CNR, state, handler, testCO, CORITE_ADMIN, SERVER_SIGNER, GENERAL_HANDLER;

  beforeEach(async function () {
    [owner, admin, artist, backer, server] = await ethers.getSigners();
    CNR = await help.setCNR();
    state = await help.setStateContract(CNR, owner.address);
    handler = await help.setHandler(state, owner.address);
    testCO = await help.setTestCO();
    GENERAL_HANDLER = await state.GENERAL_HANDLER();
    SERVER_SIGNER = await handler.SERVER_SIGNER();
    CORITE_ADMIN = await handler.CORITE_ADMIN();
    await state.connect(owner).grantRole(GENERAL_HANDLER, handler.address);
    await handler.connect(owner).grantRole(SERVER_SIGNER, server.address);
    await handler.connect(owner).grantRole(CORITE_ADMIN, admin.address);
    await handler.connect(owner).setCoriteAccount(owner.address);
    await handler.connect(admin).createCampaign(artist.address, 10000, 2000);
    await handler
      .connect(admin)
      .mintCampaignShares(firstCampaignId, 200, backer.address);
    await state.connect(backer).setApprovalForAll(handler.address, true);
  });

  it("should buy shares with native token", async function () {
    const userNonce = await state.currentNonce(backer.address);
    const sharesAmount = 200;
    const totalPrice = ethers.utils.parseEther("0.2");

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "uint", "uint"],
      [backer.address, firstCampaignId, sharesAmount, totalPrice, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);

    await handler
      .connect(backer)
      .buyCampaignSharesNative(firstCampaignId, sharesAmount, prefix, v, r, s, {
        value: ethers.utils.parseEther("0.2"),
      });
  });

  it("should buy shares with ERC20 token", async function () {
    const userNonce = await state.currentNonce(backer.address);
    const tokenAmount = 200000000;
    const sharesAmount = 200;
    const tokenAddress = testCO.address;

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "address", "uint", "uint"],
      [
        backer.address,
        firstCampaignId,
        sharesAmount,
        tokenAddress,
        tokenAmount,
        userNonce,
      ]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await handler.connect(admin).setValidToken(tokenAddress, true);
    await testCO.connect(backer).approve(handler.address, tokenAmount);
    await handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId,
        sharesAmount,
        tokenAddress,
        tokenAmount,
        prefix,
        v,
        r,
        s
      );
  });

  it("should refund shares for native tokens", async function () {
    const userNonce = await state.currentNonce(backer.address);
    const sharesAmount = 200;
    const refundAmount = ethers.utils.parseEther("0.2");

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "uint", "uint"],
      [backer.address, refundAmount, firstCampaignId, sharesAmount, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await owner.sendTransaction({
      to: handler.address,
      value: ethers.utils.parseEther("0.2"),
    });
    await handler
      .connect(backer)
      .refundCampaignSharesNative(
        firstCampaignId,
        sharesAmount,
        refundAmount,
        prefix,
        v,
        r,
        s
      );
  });

  it("should refund shares for ERC20 tokens", async function () {
    const userNonce = await state.currentNonce(backer.address);
    const tokenAmount = 2000000;
    const sharesAmount = 200;
    const tokenAddress = testCO.address;

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint", "uint", "uint", "uint"],
      [
        backer.address,
        tokenAddress,
        tokenAmount,
        firstCampaignId,
        sharesAmount,
        userNonce,
      ]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await handler.connect(admin).setValidToken(tokenAddress, true);
    await testCO.connect(owner).transfer(handler.address, tokenAmount);
    await handler
      .connect(backer)
      .refundCampaignShares(
        firstCampaignId,
        sharesAmount,
        tokenAddress,
        tokenAmount,
        prefix,
        v,
        r,
        s
      );
  });

  it("should burn campaign shares", async function () {
    const userNonce = await state.currentNonce(backer.address);
    const sharesAmount = 200;

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "uint"],
      [backer.address, firstCampaignId, sharesAmount, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await handler
      .connect(backer)
      .burnCampaignShares(firstCampaignId, sharesAmount, prefix, v, r, s);
  });
});

describe("Test collections", function () {
  var CNR, state, handler, testCO, CORITE_ADMIN, SERVER_SIGNER, GENERAL_HANDLER;

  beforeEach(async function () {
    [owner, admin, artist, backer, server] = await ethers.getSigners();
    CNR = await help.setCNR();
    state = await help.setStateContract(CNR, owner.address);
    handler = await help.setHandler(state, owner.address);
    testCO = await help.setTestCO();
    GENERAL_HANDLER = await state.GENERAL_HANDLER();
    SERVER_SIGNER = await handler.SERVER_SIGNER();
    CORITE_ADMIN = await handler.CORITE_ADMIN();
    await state.connect(owner).grantRole(GENERAL_HANDLER, handler.address);
    await handler.connect(owner).grantRole(SERVER_SIGNER, server.address);
    await handler.connect(owner).grantRole(CORITE_ADMIN, admin.address);
    await handler.connect(owner).setCoriteAccount(owner.address);
    await handler.connect(admin).createCampaign(artist.address, 10000, 2000);
    await handler
      .connect(admin)
      .mintCampaignShares(firstCampaignId, 200, backer.address);
    await state.connect(backer).setApprovalForAll(handler.address, true);
  });

  it("should buy NFT with native token", async function () {
    const userNonce = await state.currentNonce(backer.address);
    const sharesAmount = 200;
    const totalPrice = ethers.utils.parseEther("0.2");

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "uint", "uint"],
      [backer.address, firstCampaignId, sharesAmount, totalPrice, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);

    await handler
      .connect(backer)
      .buyCampaignSharesNative(firstCampaignId, sharesAmount, prefix, v, r, s, {
        value: ethers.utils.parseEther("0.2"),
      });
  });
});

async function createSignature(obj) {
  obj = ethers.utils.arrayify(obj);
  const prefix = ethers.utils.toUtf8Bytes(
    "\x19Ethereum Signed Message:\n" + obj.length
  );
  const serverSig = await server.signMessage(obj);
  const sig = ethers.utils.splitSignature(serverSig);
  return { ...sig, prefix };
}
