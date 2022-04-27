const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");
const firstCampaignId = "100000000000000000000000000000000000000000000000000000000000000000001";

var owner, admin, artist, backer;

describe("Test create campaign", function () {
  var CNR, corite, CREATE_CLOSE_HANDLER;

  beforeEach(async function () {
    [owner, admin, artist] = await ethers.getSigners();
    CNR = await help.setCNR();
    corite = await help.setStateContract(CNR, owner.address);
    CREATE_CLOSE_HANDLER = await corite.CREATE_CLOSE_HANDLER();
  });

  it("should create campaign", async function () {
    await expect(corite.connect(admin).createCampaign(artist.address, 1000000, 200000)).to.be.revertedWith(
      "CREATE_CLOSE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, admin.address);
    await expect(corite.connect(admin).createCampaign(artist.address, 0, 0)).to.be.revertedWith(
      "supplyCap/toBackersCap must be greater than 0"
    );
    await expect(corite.connect(admin).createCampaign(artist.address, 10000, 0)).to.be.revertedWith(
      "supplyCap/toBackersCap must be greater than 0"
    );
    await expect(corite.connect(admin).createCampaign(artist.address, 10000, 20000)).to.be.revertedWith(
      "supplyCap is less than toBackersCap"
    );

    await expect(corite.connect(admin).createCampaign(artist.address, 1000000, 200000))
      .to.emit(corite, "CreateCampaignEvent")
      .withArgs(artist.address, ethers.BigNumber.from(firstCampaignId));

    const campaign = await corite.campaignInfo(await corite.campaignCount());
    expect(campaign.owner).to.equal(artist.address);
    expect(campaign.supplyCap).to.equal(1000000);
    expect(campaign.toBackersCap).to.equal(200000);
    expect(campaign.closed).to.be.false;
    expect(campaign.cancelled).to.be.false;
    expect(campaign.hasMintedExcess).to.be.false;
  });
});

describe("Test campaign functionality", function () {
  var CNR, corite, campaignId, CREATE_CLOSE_HANDLER, MINTER_NONCE_HANDLER, BURNER_HANDLER;

  beforeEach(async function () {
    [owner, admin, artist, backer] = await ethers.getSigners();
    CNR = await help.setCNR();
    corite = await help.setStateContract(CNR, owner.address);

    CREATE_CLOSE_HANDLER = await corite.CREATE_CLOSE_HANDLER();
    MINTER_NONCE_HANDLER = await corite.MINTER_NONCE_HANDLER();
    BURNER_HANDLER = await corite.BURNER_HANDLER();

    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, admin.address);
    await corite.connect(admin).createCampaign(artist.address, 10000, 2000);
    campaignId = await corite.campaignCount();
  });

  it("should mint campaign shares", async function () {
    await expect(corite.connect(admin).mintCampaignShares(campaignId, 100, backer.address)).to.be.revertedWith(
      "MINTER_NONCE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(MINTER_NONCE_HANDLER, admin.address);
    await expect(corite.connect(admin).mintCampaignShares(campaignId, 3000, backer.address)).to.be.revertedWith(
      "Amount exceeds toBackersCap"
    );

    expect(await corite.balanceOf(backer.address, campaignId)).to.equal(0);
    await corite.connect(admin).mintCampaignShares(campaignId, 100, backer.address);
    expect(await corite.balanceOf(backer.address, campaignId)).to.equal(100);

    await corite.connect(admin).closeCampaign(campaignId);
    await expect(corite.connect(admin).mintCampaignShares(campaignId, 100, backer.address)).to.be.revertedWith(
      "Campaign closed/cancelled"
    );
  });

  it("should mint excess shares", async function () {
    await expect(corite.connect(admin).mintExcessShares(campaignId, owner.address)).to.be.revertedWith(
      "MINTER_NONCE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(MINTER_NONCE_HANDLER, admin.address);
    await corite.connect(admin).mintExcessShares(campaignId, backer.address);
    await expect(corite.connect(admin).mintExcessShares(campaignId, backer.address)).to.be.revertedWith(
      "Already minted or cancelled"
    );
    await corite.connect(admin).mintCampaignShares(campaignId, 1000, backer.address);
    await expect(corite.connect(admin).mintCampaignShares(campaignId, 1001, backer.address)).to.be.revertedWith(
      "Amount exceeds supplyCap"
    );
  });

  it("should close campaign", async function () {
    await expect(corite.connect(artist).closeCampaign(campaignId)).to.be.revertedWith(
      "CREATE_CLOSE_HANDLER role required"
    );
    await expect(corite.connect(admin).closeCampaign(campaignId + 1)).to.be.revertedWith("Campaign does not exist");
    await expect(corite.connect(admin).closeCampaign(campaignId))
      .to.emit(corite, "CloseCampaignEvent")
      .withArgs(ethers.BigNumber.from(firstCampaignId));
    expect((await corite.campaignInfo(campaignId)).closed).to.be.true;
  });

  it("should cancel campaign", async function () {
    await expect(corite.connect(admin).setCampaignCancelled(campaignId + 1, true)).to.be.revertedWith(
      "Campaign does not exist"
    );

    await expect(corite.connect(admin).setCampaignCancelled(campaignId, true))
      .to.emit(corite, "CancelCampaignEvent")
      .withArgs(ethers.BigNumber.from(firstCampaignId), true);
    expect((await corite.campaignInfo(campaignId)).cancelled).to.be.true;

    await expect(corite.connect(admin).setCampaignCancelled(campaignId, false))
      .to.emit(corite, "CancelCampaignEvent")
      .withArgs(ethers.BigNumber.from(firstCampaignId), false);
    expect((await corite.campaignInfo(campaignId)).cancelled).to.be.false;
  });

  it("should burn campaign shares", async function () {
    await corite.connect(owner).grantRole(MINTER_NONCE_HANDLER, admin.address);
    await corite.connect(admin).mintCampaignShares(campaignId, 100, backer.address);

    await expect(corite.connect(admin).burnToken(campaignId, 100, backer.address)).to.be.revertedWith(
      "BURNER_HANDLER role required"
    );
    await corite.connect(owner).grantRole(BURNER_HANDLER, admin.address);
    await expect(corite.connect(admin).burnToken(campaignId, 100, backer.address)).to.be.revertedWith(
      "ERC1155: caller is not owner nor approved"
    );
    await corite.connect(backer).setApprovalForAll(admin.address, true);
    await corite.connect(admin).burnToken(campaignId, 90, backer.address);
    expect(await corite.balanceOf(backer.address, campaignId)).to.equal(10);
  });
});

describe("Test collections", function () {
  var CNR, corite, CREATE_CLOSE_HANDLER;
  const firstCollectionId = "200000001000000000000000000000000000000000000000000000000000000000000";

  beforeEach(async function () {
    [owner, admin, artist, backer] = await ethers.getSigners();
    CNR = await help.setCNR();
    corite = await help.setStateContract(CNR, owner.address);
    CREATE_CLOSE_HANDLER = await corite.CREATE_CLOSE_HANDLER();
    MINTER_NONCE_HANDLER = await corite.MINTER_NONCE_HANDLER();
  });

  async function createCollection(amount) {
    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, admin.address);
    await corite.connect(admin).createCollection(artist.address, amount);
  }

  it("should create collection", async function () {
    await expect(corite.connect(admin).createCollection(artist.address, 100)).to.be.revertedWith(
      "CREATE_CLOSE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, admin.address);
    await expect(corite.connect(admin).createCollection(artist.address, 0)).to.be.revertedWith("Invalid totalSupply");
    await expect(corite.connect(admin).createCollection(artist.address, 100))
      .to.emit(corite, "CreateCollectionEvent")
      .withArgs(artist.address, ethers.BigNumber.from(firstCollectionId));

    const collection = await corite.collectionInfo(firstCollectionId);
    expect(collection.owner).to.equal(artist.address);
    expect(collection.maxTokenId).to.equal(
      ethers.BigNumber.from("200000001000000000000000000000000000000000000000000000000000000000100")
    );
    expect(collection.latestTokenId).to.equal(ethers.BigNumber.from(firstCollectionId));
    expect(collection.closed).to.be.false;
  });

  it("should mint single token", async function () {
    await createCollection(1);
    await expect(corite.connect(admin).mintCollectionSingle(firstCollectionId, backer.address)).to.be.revertedWith(
      "MINTER_NONCE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(MINTER_NONCE_HANDLER, admin.address);
    await corite.connect(admin).mintCollectionSingle(firstCollectionId, backer.address);
    await expect(corite.connect(admin).mintCollectionSingle(firstCollectionId, backer.address)).to.be.revertedWith(
      "Minting cap reached"
    );
  });

  it("should mint batch", async function () {
    await createCollection(10);
    await expect(corite.connect(admin).mintCollectionSingle(firstCollectionId, backer.address)).to.be.revertedWith(
      "MINTER_NONCE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(MINTER_NONCE_HANDLER, admin.address);
    await corite.connect(admin).mintCollectionBatch(firstCollectionId, 5, backer.address);
    await expect(corite.connect(admin).mintCollectionBatch(firstCollectionId, 6, backer.address)).to.be.revertedWith(
      "Amount exceeds supply cap"
    );
  });

  it("should close collection", async function () {
    await createCollection(10);
    await expect(corite.connect(artist).closeCollection(firstCollectionId)).to.be.revertedWith(
      "CREATE_CLOSE_HANDLER role required"
    );
    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, artist.address);

    await expect(corite.connect(artist).closeCollection(firstCollectionId))
      .to.emit(corite, "CloseCollectionEvent")
      .withArgs(ethers.BigNumber.from(firstCollectionId));

    await corite.connect(owner).grantRole(MINTER_NONCE_HANDLER, admin.address);
    await expect(corite.connect(admin).mintCollectionSingle(firstCollectionId, backer.address)).to.be.revertedWith(
      "Collection closed"
    );
    await expect(corite.connect(admin).mintCollectionBatch(firstCollectionId, 5, backer.address)).to.be.revertedWith(
      "Collection closed"
    );
  });
});
