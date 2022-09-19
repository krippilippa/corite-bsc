const hre = require("hardhat");

async function main() {
  const TestCO = await hre.ethers.getContractFactory("TestCO");
  const testCO = await TestCO.deploy();

  await testCO.deployed();
  console.log(`testCO deployed to ${testCO.address}`);

  const COStake = await hre.ethers.getContractFactory("COStake");
  const cOStake = await COStake.deploy(
    testCO.address,
    3650,
    "0xd4354fB989df7F2b1d034B9AF682A77bA3C19B48"
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
