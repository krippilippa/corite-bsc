const hre = require("hardhat");

async function main() {
  // const TestCO = await hre.ethers.getContractFactory("TestCO");
  // const testCO = await TestCO.deploy();

  // await testCO.deployed();
  // console.log(`testCO deployed to ${testCO.address}`);

  const COStake = await hre.ethers.getContractFactory("COStake");
  const cOStake = await COStake.deploy(
    "0x936B6659Ad0C1b244Ba8Efe639092acae30dc8d6",
    2433,
    "0x0000000000000000000000000000000000000000",
    "0x15f218814414fBE8255f085EE09EE6264437b51A"
  );

  await cOStake.deployed();

  console.log(`cOStake deployed to ${cOStake.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
