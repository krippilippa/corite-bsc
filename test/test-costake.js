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
    const coStake = await COStake.deploy(testCO.address);

    await coStake.deployed();

    await testCO.increaseAllowance(coStake.address, 500000000);
    await coStake.stake(1000000 * 100, 14 * 86400);
    await testCO.transfer(coStake.address, 500000000);

    await time.increaseTo((await time.latest()) + 365 * 86400);
    return { coStake, owner, otherAccount };
  }

  describe("Basics", () => {
    it("Should show yield", async () => {
      const { coStake, owner, otherAccount } = await loadFixture(deployCOStake);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      console.log(yield / 1000000);
    });
    it("Should let claim yield", async () => {
      const { coStake, owner, otherAccount } = await loadFixture(deployCOStake);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      console.log(yield / 1000000);

      await expect(coStake.claimYield()).to.not.be.reverted;

      await time.increaseTo((await time.latest()) + 100 * 86400);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      console.log(yield / 1000000);
      await expect(coStake.claimYield()).to.not.be.reverted;

      await time.increaseTo((await time.latest()) + 22 * 86400);
      var [sum, sumstrict, yield] = await coStake.estimateAccumulated(
        owner.address
      );
      console.log(yield / 1000000);
    });
    // it("Should not let claim yield when claimable yield is 0", async () => {
    //   const { coStake, twoWeeksNotice, owner, otherAccount } =
    //     await loadFixture(deployCOStake);
    //   await twoWeeksNotice.requestWithdraw();
    //   await coStake.claimYield();
    //   await expect(coStake.claimYield()).to.be.reverted;
    // });
  });
});
