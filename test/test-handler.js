const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");
const firstCampaignId =
  "100000000000000000000000000000000000000000000000000000000000000000001";
var owner, admin, artist, backer, server, CNR, userNonce, state, handler, testCO, CORITE_ADMIN, SERVER_SIGNER, GENERAL_HANDLER;
const sharesAmount = 200;

describe("Test campaigns", function () {
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
    userNonce = await state.currentNonce(backer.address);

  });

  it("should buy shares with native token", async function () {
    const totalPrice = ethers.utils.parseEther("0.2");
    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "address", "uint", "uint"],
      [
        backer.address,
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        totalPrice,
        userNonce,
      ]
    );
    const { prefix, v, r, s } = await createSignature(obj);
     await expect(handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        totalPrice,
        prefix,
        v,
        r,
        s, {
        value: ethers.utils.parseEther("0.1"),
      })).to.be.revertedWith("Invalid token amount");
    await handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        totalPrice,
        prefix,
        v,
        r,
        s, {
        value: ethers.utils.parseEther("0.2"),
      });
      await expect(handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        totalPrice,
        prefix,
        v,
        r,
        s, {
        value: ethers.utils.parseEther("0.2"),
      })).to.be.revertedWith("Invalid server signature");
  });

  it("should buy shares with ERC20 token", async function () {
    const tokenAmount = 200000000;
    const tokenAddress = testCO.address;

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "address", "uint", "uint"],
      [
        backer.address, firstCampaignId, sharesAmount, tokenAddress, tokenAmount, userNonce
      ]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await expect(handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId, sharesAmount, tokenAddress, tokenAmount, prefix, v, r, s
      )).to.be.revertedWith("Invalid token address");
    await handler.connect(admin).setValidToken(tokenAddress, true);
    await testCO.connect(backer).approve(handler.address, tokenAmount);
    await handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId, sharesAmount, tokenAddress, tokenAmount, prefix, v, r, s
      );
     await expect(handler
      .connect(backer)
      .buyCampaignShares(
        firstCampaignId, sharesAmount, tokenAddress, tokenAmount, prefix, v, r, s
      )).to.be.revertedWith("Invalid server signature");
  });

  it("should refund shares for native tokens", async function () {
    const refundAmount = ethers.utils.parseEther("0.2");
    let obj = ethers.utils.defaultAbiCoder.encode(
       ["address", "address", "uint", "uint", "uint", "uint"],
      [
        backer.address,
        ethers.constants.AddressZero,
        refundAmount,
        firstCampaignId,
        sharesAmount,
        userNonce,
      ]
    );
    const { prefix, v, r, s } = await createSignature(obj);
     await expect(handler
      .connect(backer)
      .refundCampaignShares(
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        refundAmount,
        prefix,
        v,
        r,
        s
      )).to.be.revertedWith("Failed to transfer native token");
    await owner.sendTransaction({
      to: handler.address,
      value: ethers.utils.parseEther("0.4"),
    });
    await handler
      .connect(backer)
      .refundCampaignShares(
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        refundAmount,
        prefix,
        v,
        r,
        s
      );
      await expect(handler
      .connect(backer)
      .refundCampaignShares(
        firstCampaignId,
        sharesAmount,
        ethers.constants.AddressZero,
        refundAmount,
        prefix,
        v,
        r,
        s
      )).to.be.revertedWith("Invalid server signature");
      expect(await ethers.provider.getBalance(handler.address)).to.be.equal(ethers.utils.parseEther("0.2"))
      await handler.connect(owner).withdrawNativeTokens();
      expect(await ethers.provider.getBalance(handler.address)).to.be.equal(0);
  });

  it("should refund shares for ERC20 tokens", async function () {
    const tokenAmount = 2000000;
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
    await expect(handler
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
      )).to.be.revertedWith("Invalid token address");
    await handler.connect(admin).setValidToken(tokenAddress, true);
    await handler.connect(owner).setRefundAccount(admin.address);
    await testCO.connect(admin).approve(handler.address, tokenAmount);
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
      await expect(handler
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
      )).to.be.revertedWith("Invalid server signature");
  });

  it("should burn campaign shares", async function () {
    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "uint"],
      [backer.address, firstCampaignId, sharesAmount, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await handler
      .connect(backer)
      .burnCampaignShares(firstCampaignId, sharesAmount, prefix, v, r, s);
    await expect(handler
      .connect(backer)
      .burnCampaignShares(firstCampaignId, sharesAmount, prefix, v, r, s))
      .to.be.revertedWith("Invalid server signature");
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
    let ownerCollectionCount = await state.getCollectionCount(artist.address);
    let totalSupply = 1000;
    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint"],
      [artist.address, totalSupply, ownerCollectionCount]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await handler.connect(artist).createCollection(artist.address, totalSupply, prefix, v, r, s);
  });

  it("should create collection", async function () {
    let ownerCollectionCount = await state.getCollectionCount(artist.address);
    let totalSupply = 1000;
    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint"],
      [artist.address, totalSupply, ownerCollectionCount]
    );
    const { prefix, v, r, s } = await createSignature(obj);
    await handler
      .connect(artist)
      .createCollection(artist.address, totalSupply, prefix, v, r, s);
    await expect(handler
      .connect(artist)
      .createCollection(artist.address, totalSupply, prefix, v, r, s))
      .to.be.revertedWith("Invalid server signature");
  });

  it("should buy NFTs with native token", async function () {
    const nativeAmount = ethers.utils.parseEther("0.2");  
     let id = await state.latestCollectionId();

     let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "address", "uint", "uint"],
      [backer.address, id, 1, ethers.constants.AddressZero, nativeAmount, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);
     await expect(handler
      .connect(backer)
      .payToMintNFTs(id, 1, ethers.constants.AddressZero, nativeAmount, prefix, v, r, s, {
        value: ethers.utils.parseEther("0.1"),
      })).to.be.revertedWith("Invalid token amount");
    await handler
      .connect(backer)
      .payToMintNFTs(id, 1, ethers.constants.AddressZero, nativeAmount, prefix, v, r, s, {
        value: nativeAmount,
      });
    await expect(handler
      .connect(backer)
      .payToMintNFTs(id, 1, ethers.constants.AddressZero, nativeAmount, prefix, v, r, s, {
        value: nativeAmount,
      })).to.be.revertedWith("Invalid server signature");
  })

  it("should buy NFTs with ERC20 token", async function () {
    const tokenAmount = 100000;
    const tokenAddress = testCO.address;
     let id = await state.latestCollectionId();

     let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "address", "uint", "uint"],
      [backer.address, id, 5, tokenAddress, tokenAmount, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);
     await expect(handler
      .connect(backer)
      .payToMintNFTs(id, 5, tokenAddress, tokenAmount, prefix, v, r, s))
      .to.be.revertedWith("Invalid token address");
    await handler.connect(admin).setValidToken(tokenAddress, true);
    await testCO.connect(backer).approve(handler.address, tokenAmount);
    await handler
      .connect(backer)
      .payToMintNFTs(id, 5, tokenAddress, tokenAmount, prefix, v, r, s);
    await expect(handler
      .connect(backer)
      .payToMintNFTs(id, 5, tokenAddress, tokenAmount, prefix, v, r, s))
      .to.be.revertedWith("Invalid server signature");
  })

  it("should mint NFTs with signature", async function () {
    let id = await state.latestCollectionId();

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "uint", "uint"],
      [backer.address, id, 5, userNonce]
    );
    const { prefix, v, r, s } = await createSignature(obj);

    await handler.connect(backer).mintNFTs(id, 5, prefix, v, r, s);
    await expect(handler.connect(backer).mintNFTs(id, 5, prefix, v, r, s))
    .to.be.revertedWith("Invalid server signature");
  })
});

describe("Test staking", function () {
  let now;
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
    await handler.connect(owner).setCOtoken(testCO.address);
    userNonce = await state.currentNonce(backer.address);
    await testCO.connect(backer).approve(handler.address, 300);

  });

  it("should set stakingInfo", async function () {
    now = Date.now();
    let start = now + 100;
    let stop = start + 1000*10;
    let release = stop + 1000*2;
    await handler.connect(admin).mintCampaignShares(firstCampaignId, 1000, owner.address)
    await expect(handler.connect(admin).registerStakeInfo(firstCampaignId, start, stop, release))
        .to.be.revertedWith("Can not register stake after minting shares");

    await state.connect(owner).grantRole(GENERAL_HANDLER, owner.address);
    await state.connect(owner).burnToken(firstCampaignId, 1000, owner.address);

    await expect(handler.connect(admin).registerStakeInfo(firstCampaignId + 1, start, stop, release))
        .to.be.revertedWith("Invalid campaign id");

    await ethers.provider.send("evm_setNextBlockTimestamp", [now]);
    await expect(handler.connect(admin).registerStakeInfo(firstCampaignId, now-100, stop, release))
        .to.be.revertedWith("Invalid timestamp order");
    await expect(handler.connect(admin).registerStakeInfo(firstCampaignId, stop, start, release))
        .to.be.revertedWith("Invalid timestamp order");
    await expect(handler.connect(admin).registerStakeInfo(firstCampaignId, start, release, stop))
        .to.be.revertedWith("Invalid timestamp order");
    await handler.connect(admin).registerStakeInfo(firstCampaignId, start, stop, release);
    await handler.connect(admin).registerStakeInfo(firstCampaignId, start, stop, release + 1000);

    await ethers.provider.send("evm_setNextBlockTimestamp", [start + 100]);
    await handler.connect(backer).stake(firstCampaignId, 100);
    await expect(handler.connect(admin).registerStakeInfo(firstCampaignId, start, stop, release + 2000))
        .to.be.revertedWith("Can not change info after staking has started");
    
  });

  it("should add stake", async function () {
    now = Date.now();
    await expect(handler.connect(backer).stake(firstCampaignId, 100))
        .to.be.revertedWith("Staking for this campaign is not active");
    await handler.connect(admin).registerStakeInfo(firstCampaignId, now + 100, now + 3000, now + 5000);
    await expect(handler.connect(backer).stake(firstCampaignId, 100))
        .to.be.revertedWith("Staking for this campaign is not active");
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 200]);
    await handler.connect(backer).stake(firstCampaignId, 100);
    expect(await handler.stakeInCampaign(backer.address, firstCampaignId)).to.be.equal(100);
    expect((await handler.campaignStakeInfo(firstCampaignId)).stakedCOs).to.be.equal(100);
    await handler.connect(backer).stake(firstCampaignId, 100);
    expect(await handler.stakeInCampaign(backer.address, firstCampaignId)).to.be.equal(200);
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 3100]);
    await expect(handler.connect(backer).stake(firstCampaignId, 100))
        .to.be.revertedWith("Staking for this campaign is not active");
  });

  it("should release stake", async function () {
    now = Date.now();
    await handler.connect(admin).registerStakeInfo(firstCampaignId, now + 10000, now + 30000, now + 50000);
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 20000]);
    await handler.connect(backer).stake(firstCampaignId, 100);
    await expect(handler.connect(backer).releaseStake(firstCampaignId))
        .to.be.revertedWith("Can not release stake before release date");
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 40000]);
    await expect(handler.connect(backer).releaseStake(firstCampaignId))
        .to.be.revertedWith("Can not release stake before release date");
    let balance = await testCO.balanceOf(backer.address);
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 51000]);
    await handler.connect(backer).releaseStake(firstCampaignId);
    expect(await testCO.balanceOf(backer.address)).to.be.equal(Number(balance) + 100);
    await expect(handler.connect(backer).releaseStake(firstCampaignId))
        .to.be.revertedWith("Nothing staked");
  });

  it("should prevent minting shares before stake end", async function () {
    now = Date.now();
    await handler.connect(admin).registerStakeInfo(firstCampaignId, now + 100000, now + 300000, now + 500000);
    await expect(handler.connect(admin).mintCampaignShares(firstCampaignId, 1000, backer.address))
        .to.be.revertedWith("Staking phase is not over");
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 310000]);
    await handler.connect(admin).mintCampaignShares(firstCampaignId, 1000, backer.address);
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