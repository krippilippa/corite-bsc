const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("COStakeReward", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployCOStakeReward() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const TestCO = await ethers.getContractFactory("TestCO");
    const testCO = await TestCO.deploy();

    await testCO.deployed();

    await testCO.faucet();

    const TwoWeeksNotice = await ethers.getContractFactory("TwoWeeksNotice");
    const twoWeeksNotice = await TwoWeeksNotice.deploy(testCO.address);

    await twoWeeksNotice.deployed();

    await testCO.increaseAllowance(twoWeeksNotice.address, 1000000000);
    await twoWeeksNotice.stake(1000000 * 100, 500 * 86400);

    const COStakeReward = await ethers.getContractFactory("COStakeReward");
    const coStakeReward = await COStakeReward.deploy(twoWeeksNotice.address);

    await coStakeReward.deployed();
    return { coStakeReward, owner, otherAccount };
  }

  describe("Basics", () => {
    it("Should give reward", async () => {
      const { coStakeReward, owner, otherAccount } = await loadFixture(
        deployCOStakeReward
      );
      await time.increaseTo((await time.latest()) + 365 * 86400);
      var reward = await coStakeReward.estimateReward();
      console.log(reward / 1000000);
    });
  });
});
