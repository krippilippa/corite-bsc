const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const tokenIDs = require("./COVariousTokenIds.json");

describe("OriginsNFTBurn", function () {
  this.timeout(100000);
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOriginsNFTBurn() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const TestCO = await ethers.getContractFactory("TestCO");
    const testCO = await TestCO.deploy();

    await testCO.deployed();

    await testCO.connect(otherAccount).faucet();

    const Test721 = await ethers.getContractFactory("CoriteMNFT");
    const test721 = await Test721.deploy(
      ethers.constants.AddressZero,
      owner.address
    );

    await test721.deployed();

    const OriginsNFTBurn = await ethers.getContractFactory("OriginsNFTBurn");
    const originsNFTBurn = await OriginsNFTBurn.deploy(
      test721.address,
      testCO.address,
      otherAccount.address,
      owner.address,
      owner.address
    );

    await originsNFTBurn.deployed();

    await test721.grantRole(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BURNER")),
      originsNFTBurn.address
    );
    await test721.grantRole(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER")),
      owner.address
    );
    await test721.mint(owner.address, 0);

    await testCO
      .connect(otherAccount)
      .increaseAllowance(originsNFTBurn.address, 10000000);
    await test721.approve(originsNFTBurn.address, 0);

    return { originsNFTBurn, test721, testCO, owner, otherAccount };
  }

  describe("Verification", () => {
    it("Should verify correct signer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { prefix, v, r, s } = await createSignature(message, owner);

      await expect(
        originsNFTBurn.burnAndClaimBacker([0], v, r, s)
      ).to.not.be.revertedWith("Invalid sign");
    });
    it("Should not verify bad signer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { prefix, v, r, s } = await createSignature(message, otherAccount);
      await expect(
        originsNFTBurn.burnAndClaimBacker([0], v, r, s)
      ).to.be.revertedWith("Invalid sign");
    });
    it("Should not let use someone elses token", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [otherAccount.address]
      );

      const { prefix, v, r, s } = await createSignature(message, owner);
      await expect(
        originsNFTBurn.connect(otherAccount).burnAndClaimBacker([0], v, r, s)
      ).to.be.revertedWith("Not NFT Owner");
    });
  });
  describe("Claiming", () => {
    it("Should burn the NFT as backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { v, r, s } = await createSignature(message, owner);
      await expect(test721.ownerOf(0)).to.not.be.revertedWith(
        "ERC721: invalid token ID"
      );
      await originsNFTBurn.burnAndClaimBacker([0], v, r, s);
      await expect(test721.ownerOf(0)).to.be.revertedWith(
        "ERC721: invalid token ID"
      );
    });
    it("Should burn the NFT as non-backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      await expect(test721.ownerOf(0)).to.not.be.revertedWith(
        "ERC721: invalid token ID"
      );
      await originsNFTBurn.burnAndClaimNonBacker([0]);
      await expect(test721.ownerOf(0)).to.be.revertedWith(
        "ERC721: invalid token ID"
      );
    });

    it("Should give CO tokens as backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { v, r, s } = await createSignature(message, owner);
      var b0 = await testCO.balanceOf(owner.address);
      await originsNFTBurn.burnAndClaimBacker([0], v, r, s);
      var b1 = await testCO.balanceOf(owner.address);
      console.log("Won " + (b1 - b0) + "!");
    });
    it("Should give CO tokens as non-backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      var b0 = await testCO.balanceOf(owner.address);
      await originsNFTBurn.burnAndClaimNonBacker([0]);
      var b1 = await testCO.balanceOf(owner.address);
      console.log("Won " + (b1 - b0) + "!");
    });
  });
  describe("Distributions", () => {
    it("Should give a 'random' number", async () => {
      const { originsNFTBurn, owner, otherAccount } = await loadFixture(
        deployOriginsNFTBurn
      );
      console.log(await originsNFTBurn.tokenIdToNum(16202211399020));
    });

    it("True distribution", async () => {
      const { originsNFTBurn, owner, otherAccount } = await loadFixture(
        deployOriginsNFTBurn
      );

      var counts = [0, 0, 0, 0, 0, 0, 0];

      for (let i = 0; i < tokenIDs.length; i++) {
        var num = await originsNFTBurn.tokenIdToNum(tokenIDs[i]);
        if (num == 0) {
          counts[0]++;
        } else if (num < 5) {
          counts[1]++;
        } else if (num < 15) {
          counts[2]++;
        } else if (num < 65) {
          counts[3]++;
        } else if (num < 200) {
          counts[4]++;
        } else if (num < 700) {
          counts[5]++;
        } else {
          counts[6]++;
        }
      }
      console.log("Counts: ", counts);
    });

    it("Distribution random 10000", async () => {
      const { originsNFTBurn, owner, otherAccount } = await loadFixture(
        deployOriginsNFTBurn
      );

      var counts = [0, 0, 0, 0, 0, 0, 0];

      for (let i = 0; i < 10000; i++) {
        var num = await originsNFTBurn.tokenIdToNum(getRandomInt(1000000));
        if (num == 0) {
          counts[0]++;
        } else if (num < 5) {
          counts[1]++;
        } else if (num < 15) {
          counts[2]++;
        } else if (num < 65) {
          counts[3]++;
        } else if (num < 200) {
          counts[4]++;
        } else if (num < 700) {
          counts[5]++;
        } else {
          counts[6]++;
        }
      }
      console.log("Counts: ", counts);
    });
    it("Distribution random 1000", async () => {
      const { originsNFTBurn, owner, otherAccount } = await loadFixture(
        deployOriginsNFTBurn
      );

      var counts = [0, 0, 0, 0, 0, 0, 0];

      for (let i = 0; i < 1000; i++) {
        var num = await originsNFTBurn.tokenIdToNum(getRandomInt(1000000));
        if (num == 0) {
          counts[0]++;
        } else if (num < 5) {
          counts[1]++;
        } else if (num < 15) {
          counts[2]++;
        } else if (num < 65) {
          counts[3]++;
        } else if (num < 200) {
          counts[4]++;
        } else if (num < 700) {
          counts[5]++;
        } else {
          counts[6]++;
        }
      }
      console.log("Counts: ", counts);
    });
  });
});

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

async function createSignature(obj, signer) {
  obj = ethers.utils.arrayify(obj);
  const prefix = ethers.utils.toUtf8Bytes(
    "\x19Ethereum Signed Message:\n" + obj.length
  );
  const serverSig = await signer.signMessage(obj);
  const sig = ethers.utils.splitSignature(serverSig);
  return { ...sig, prefix };
}
