const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CO_claim", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  // describe("Nonce", function () {});

  async function deployCOclaim() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const TestCO = await ethers.getContractFactory("TestCO");
    const testCO = await TestCO.deploy();

    await testCO.deployed();

    await testCO.faucet();

    const CO_claim = await ethers.getContractFactory("CO_claim");
    const co_claim = await CO_claim.deploy(
      testCO.address,
      owner.address,
      owner.address
    );

    await co_claim.deployed();

    await testCO.transfer(co_claim.address, 1000000);

    return { co_claim, testCO, owner, otherAccount };
  }
  describe("Verification", function () {
    it("Should successfully verify", async () => {
      const { co_claim, testCO, owner, otherAccount } = await loadFixture(
        deployCOclaim
      );

      let claimAmount = 10000;
      let nonce = await co_claim.internalNonce(owner.address);

      let message = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint", "uint"],
        [owner.address, claimAmount, nonce]
      );
      // Sign a transaction for claimAmount
      const { prefix, v, r, s } = await createSignature(message, owner);

      // Try to claim prize
      await expect(co_claim.claimCO(claimAmount, v, r, s)).to.not.be.reverted;
    });

    it("Should revert because of bad signer", async () => {
      const { co_claim, testCO, owner, otherAccount } = await loadFixture(
        deployCOclaim
      );

      let claimAmount = 10000;
      let nonce = await co_claim.internalNonce(owner.address);

      let message = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint", "uint"],
        [owner.address, claimAmount, nonce]
      );
      // Sign a transaction for claimAmount
      const { prefix, v, r, s } = await createSignature(message, otherAccount);

      // Try to claim prize
      await expect(co_claim.claimCO(claimAmount, v, r, s)).to.be.reverted;
    });
  });
});

async function createSignature(obj, signer) {
  obj = ethers.utils.arrayify(obj);
  const prefix = ethers.utils.toUtf8Bytes(
    "\x19Ethereum Signed Message:\n" + obj.length
  );
  const serverSig = await signer.signMessage(obj);
  const sig = ethers.utils.splitSignature(serverSig);
  return { ...sig, prefix };
}
