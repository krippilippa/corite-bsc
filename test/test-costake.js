const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("COStake", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployCOStake() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const TestCO = await ethers.getContractFactory("TestCO");
    const testCO = await TestCO.deploy();

    await testCO.deployed();

    await testCO.faucet();

    const COStake = await ethers.getContractFactory("COStake");
    const coStake = await COStake.deploy(testCO.address, 3650);

    await coStake.deployed();

    await testCO.increaseAllowance(coStake.address, 500000000);
    await coStake.stake(1000000 * 100, 14 * 86400);
    await testCO.transfer(coStake.address, 500000000);

    await time.increaseTo((await time.latest()) + 365 * 86400);
    return { coStake, testCO, owner, otherAccount };
  }

  describe("Yield Staking", () => {
    it("Should estimate yield correctly", async () => {
      const { coStake, owner, otherAccount } = await loadFixture(deployCOStake);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      expect(yield / 1000000).to.be.equal(10);
    });
    it("Should let claim yield", async () => {
      const { coStake, testCO, owner, otherAccount } = await loadFixture(
        deployCOStake
      );
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      var initial_balance = await testCO.balanceOf(owner.address);
      await coStake.claimYield();

      var following_balance = await testCO.balanceOf(owner.address);
      await expect(following_balance - initial_balance).to.be.equal(yield);
    });

    it("Should set claimable yield to 0 when yield is claimed", async () => {
      const { coStake, owner, otherAccount } = await loadFixture(deployCOStake);

      await coStake.claimYield();

      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      expect(yield).to.be.equal(0);
    });
    it("Should give hold correct yield when yield rate changes", async () => {
      const { coStake, owner, otherAccount } = await loadFixture(deployCOStake);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );

      await coStake.setYieldRate(1825);

      await time.increaseTo((await time.latest()) + 365 * 86400);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      expect(yield / 1000000).to.be.equal(30);
    });

    it("Should not give yield when paused", async () => {
      const { coStake, owner, otherAccount } = await loadFixture(deployCOStake);
      var [sum, sumstrict, yield1] = await coStake.estimateAccumulated(
        owner.address
      );
      await coStake.pauseYield();
      await time.increaseTo((await time.latest()) + 365 * 86400);

      var [sum, sumstrict, yield2] = await coStake.estimateAccumulated(
        owner.address
      );
      expect(yield1).to.be.equal(yield2);
    });
  });
});
