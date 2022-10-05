const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OriginsNFTBurn", function () {
  this.timeout(100000);
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOriginsNFTBurn() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const OriginsNFTBurn = await ethers.getContractFactory("OriginsNFTBurn");
    const originsNFTBurn = await OriginsNFTBurn.deploy(
      ethers.constants.AddressZero,
      ethers.constants.AddressZero
    );

    await originsNFTBurn.deployed();

    return { originsNFTBurn, owner, otherAccount };
  }
  it("Should give a random number", async () => {
    const { originsNFTBurn, owner, otherAccount } = await loadFixture(
      deployOriginsNFTBurn
    );
    console.log(await originsNFTBurn.claimAndBurn(16202211399020));
  });

  it("How many out of 10000 get 500 CO?", async () => {
    const { originsNFTBurn, owner, otherAccount } = await loadFixture(
      deployOriginsNFTBurn
    );
    var count = 0;
    for (let i = 0; i < 10000; i++) {
      if ((await originsNFTBurn.claimAndBurn(getRandomInt(1000000))) == 1) {
        count++;
      }
    }
    console.log(count);
  });
  it("How many out of 10000 get 1 CO?", async () => {
    const { originsNFTBurn, owner, otherAccount } = await loadFixture(
      deployOriginsNFTBurn
    );
    var count = 0;
    for (let i = 0; i < 10000; i++) {
      if ((await originsNFTBurn.claimAndBurn(getRandomInt(1000000))) > 500) {
        count++;
      }
    }
    console.log(count);
  });
  it("Distribution 10000", async () => {
    const { originsNFTBurn, owner, otherAccount } = await loadFixture(
      deployOriginsNFTBurn
    );

    var counts = [0, 0, 0, 0, 0, 0, 0];

    for (let i = 0; i < 10000; i++) {
      var num = await originsNFTBurn.claimAndBurn(getRandomInt(1000000));
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
  it("Distribution 1000", async () => {
    const { originsNFTBurn, owner, otherAccount } = await loadFixture(
      deployOriginsNFTBurn
    );

    var counts = [0, 0, 0, 0, 0, 0, 0];

    for (let i = 0; i < 1000; i++) {
      var num = await originsNFTBurn.claimAndBurn(getRandomInt(1000000));
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

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}
