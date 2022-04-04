const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");

describe("Test create campaign", function () {
  var CNR, corite, CREATE_CLOSE_HANDLER;

  beforeEach(async function () {
    const [owner] = await ethers.getSigners();
    CNR = await help.setCNR();
    corite = await help.setBaseContract(CNR, owner.address);
    CREATE_CLOSE_HANDLER = await corite.CREATE_CLOSE_HANDLER();
  });

  it("should create campaign", async function () {
    const [owner, admin, artist] = await ethers.getSigners();
    CREATE_CLOSE_HANDLER = await corite.CREATE_CLOSE_HANDLER();

    await expect(
      corite.connect(admin).createCampaign(artist.address, 1000000, 200000)
    ).to.be.revertedWith("CREATE_CLOSE_HANDLER role required");
    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, admin.address);
    await expect(
      corite.connect(admin).createCampaign(artist.address, 0, 0)
    ).to.be.revertedWith(
      "Both supplyCap and toBackersCap must be greater than 0"
    );
    await expect(
      corite.connect(admin).createCampaign(artist.address, 10000, 0)
    ).to.be.revertedWith(
      "Both supplyCap and toBackersCap must be greater than 0"
    );
    await expect(
      corite.connect(admin).createCampaign(artist.address, 10000, 20000)
    ).to.be.revertedWith("supplyCap much be greater or equal to toBackersCap");

    await corite.connect(admin).createCampaign(artist.address, 1000000, 200000);

    const campaign = await corite.campaignInfo(await corite.campaignCount());
    expect(campaign.owner).to.equal(artist.address);
    expect(campaign.supplyCap).to.equal(1000000);
    expect(campaign.toBackersCap).to.equal(200000);
    expect(campaign.closed).to.be.false;
    expect(campaign.cancelled).to.be.false;
  });
});

describe("Test campaign functionality", function () {
  var CNR,
    corite,
    campaignId,
    CREATE_CLOSE_HANDLER,
    MINTER_HANDLER,
    BURNER_HANDLER;

  beforeEach(async function () {
    const [owner, admin, artist] = await ethers.getSigners();
    CNR = await help.setCNR();
    corite = await help.setBaseContract(CNR, owner.address);

    CREATE_CLOSE_HANDLER = await corite.CREATE_CLOSE_HANDLER();
    MINTER_HANDLER = await corite.MINTER_HANDLER();
    BURNER_HANDLER = await corite.BURNER_HANDLER();

    await corite.connect(owner).grantRole(CREATE_CLOSE_HANDLER, admin.address);
    await corite.connect(admin).createCampaign(artist.address, 10000, 2000);
    campaignId = await corite.campaignCount();
  });

  it("should mint campaign shares", async function () {
    const [owner, admin, artist, backer] = await ethers.getSigners();

    await expect(
      corite.connect(admin).mintCampaignShares(campaignId, 100, backer.address)
    ).to.be.revertedWith("MINTER_HANDLER role required");
    await corite.connect(owner).grantRole(MINTER_HANDLER, admin.address);
    await expect(
      corite.connect(admin).mintCampaignShares(campaignId, 3000, backer.address)
    ).to.be.revertedWith("Amount exceeds backer supply cap");

    expect(await corite.balanceOf(backer.address, campaignId)).to.equal(0);
    await corite
      .connect(admin)
      .mintCampaignShares(campaignId, 100, backer.address);
    expect(await corite.balanceOf(backer.address, campaignId)).to.equal(100);

    await corite.connect(admin).closeCampaign(campaignId);
    await expect(
      corite.connect(admin).mintCampaignShares(campaignId, 100, backer.address)
    ).to.be.revertedWith("Campaign is closed");
  });

  it("should close campaign", async function () {
    const [owner, admin, artist, backer] = await ethers.getSigners();

    await expect(
      corite.connect(artist).closeCampaign(campaignId)
    ).to.be.revertedWith("CREATE_CLOSE_HANDLER role required");
    await expect(
      corite.connect(admin).closeCampaign(campaignId + 1)
    ).to.be.revertedWith("Campaign does not exist");
    await corite.connect(admin).closeCampaign(campaignId);
    expect((await corite.campaignInfo(campaignId)).closed).to.be.true;
  });

  it("should cancel campaign", async function () {
    const [owner, admin] = await ethers.getSigners();

    await expect(
      corite.connect(admin).setCampaignCancelled(campaignId, true)
    ).to.be.revertedWith("BURNER_HANDLER role required");
    await corite.connect(owner).grantRole(BURNER_HANDLER, admin.address);
    await expect(
      corite.connect(admin).setCampaignCancelled(campaignId + 1, true)
    ).to.be.revertedWith("Campaign does not exist");
    await corite.connect(admin).setCampaignCancelled(campaignId, true);
    expect((await corite.campaignInfo(campaignId)).cancelled).to.be.true;

    await corite.connect(admin).setCampaignCancelled(campaignId, false);
    expect((await corite.campaignInfo(campaignId)).cancelled).to.be.false;
  });

  it("should burn campaign shares", async function () {
    const [owner, admin, artist, backer] = await ethers.getSigners();

    await corite.connect(owner).grantRole(MINTER_HANDLER, admin.address);
    await corite
      .connect(admin)
      .mintCampaignShares(campaignId, 100, backer.address);

    await expect(
      corite.connect(admin).burnToken(campaignId, 100, backer.address)
    ).to.be.revertedWith("BURNER_HANDLER role required");
    await corite.connect(owner).grantRole(BURNER_HANDLER, admin.address);
    await expect(
      corite.connect(admin).burnToken(campaignId, 100, backer.address)
    ).to.be.revertedWith("ERC1155: caller is not owner nor approved");
    await corite.connect(backer).setApprovalForAll(admin.address, true);
    await corite.connect(admin).burnToken(campaignId, 90, backer.address);
    expect(await corite.balanceOf(backer.address, campaignId)).to.equal(10);
  });
});
