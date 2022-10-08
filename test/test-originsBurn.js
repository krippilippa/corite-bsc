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
    await test721.mint(owner.address, 1000000301);

    await testCO
      .connect(otherAccount)
      .transfer(originsNFTBurn.address, 1000000000);
    await test721.approve(originsNFTBurn.address, 1000000301);

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
        originsNFTBurn.burnAndClaimBacker([1000000301], v, r, s)
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
        originsNFTBurn
          .connect(otherAccount)
          .burnAndClaimBacker([1000000301], v, r, s)
      ).to.be.revertedWith("Not NFT Owner");
    });
  });
  describe("Claiming", () => {
    it("Should not let claim wrong token group", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { v, r, s } = await createSignature(message, owner);

      await test721.mint(owner.address, 1030000301);

      await test721.approve(originsNFTBurn.address, 1030000301);
      await expect(
        originsNFTBurn.burnAndClaimBacker([1030000301], v, r, s)
      ).to.be.revertedWith("Wrong token group");

      await test721.mint(owner.address, 10000000301);

      await test721.approve(originsNFTBurn.address, 10000000301);
      await expect(
        originsNFTBurn.burnAndClaimBacker([10000000301], v, r, s)
      ).to.be.revertedWith("Wrong token group");

      await test721.mint(owner.address, 100000301);

      await test721.approve(originsNFTBurn.address, 100000301);
      await expect(
        originsNFTBurn.burnAndClaimBacker([100000301], v, r, s)
      ).to.be.revertedWith("Wrong token group");

      await test721.mint(owner.address, 1);

      await test721.approve(originsNFTBurn.address, 1);
      await expect(
        originsNFTBurn.burnAndClaimBacker([1], v, r, s)
      ).to.be.revertedWith("Wrong token group");
    });

    it("Should allow correct token groups", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { v, r, s } = await createSignature(message, owner);

      await expect(
        originsNFTBurn.burnAndClaimBacker([1000000301], v, r, s)
      ).to.not.be.revertedWith("Wrong token group");

      await test721.mint(owner.address, 1001000301);

      await test721.approve(originsNFTBurn.address, 1001000301);
      await expect(
        originsNFTBurn.burnAndClaimBacker([1001000301], v, r, s)
      ).to.not.be.revertedWith("Wrong token group");

      await test721.mint(owner.address, 1032000301);

      await test721.approve(originsNFTBurn.address, 1032000301);
      await expect(
        originsNFTBurn.burnAndClaimBacker([1032000301], v, r, s)
      ).to.not.be.revertedWith("Wrong token group");
    });

    it("Should burn the NFT as backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      let message = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [owner.address]
      );

      const { v, r, s } = await createSignature(message, owner);
      await expect(test721.ownerOf(1000000301)).to.not.be.revertedWith(
        "ERC721: invalid token ID"
      );
      await originsNFTBurn.burnAndClaimBacker([1000000301], v, r, s);
      await expect(test721.ownerOf(1000000301)).to.be.revertedWith(
        "ERC721: invalid token ID"
      );
    });
    it("Should burn the NFT as non-backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      await expect(test721.ownerOf(1000000301)).to.not.be.revertedWith(
        "ERC721: invalid token ID"
      );
      await originsNFTBurn.burnAndClaimNonBacker([1000000301]);
      await expect(test721.ownerOf(1000000301)).to.be.revertedWith(
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
      await originsNFTBurn.burnAndClaimBacker([1000000301], v, r, s);
      var b1 = await testCO.balanceOf(owner.address);
      console.log("Won " + (b1 - b0) + "!");
    });
    it("Should give CO tokens as non-backer", async () => {
      const { originsNFTBurn, test721, testCO, owner, otherAccount } =
        await loadFixture(deployOriginsNFTBurn);
      var b0 = await testCO.balanceOf(owner.address);
      await originsNFTBurn.burnAndClaimNonBacker([1000000301]);
      var b1 = await testCO.balanceOf(owner.address);
      console.log("Won " + (b1 - b0) / 1000000 + "!");
    });
  });
  describe("Distributions", () => {
    xit("Should give a 'random' number", async () => {
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
        if (
          !["1000", "1001", "1032"].includes(
            tokenIDs[i].toString().substring(0, 4)
          )
        ) {
          continue;
        }
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

    xit("Distribution random 10000", async () => {
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
    xit("Distribution random 1000", async () => {
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
