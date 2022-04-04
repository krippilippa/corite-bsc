const { ethers } = require("hardhat");

async function setCNR() {
  const ChromiaNetResolver = await ethers.getContractFactory(
    "ChromiaNetResolver"
  );
  const chromiaNetResolver = await ChromiaNetResolver.deploy();
  await chromiaNetResolver.deployed();
  return chromiaNetResolver;
}

async function setBaseContract(_cnr, _defaultAdmin) {
  const Contract = await ethers.getContractFactory("Corite_ERC1155");
  const contract = await Contract.deploy(_cnr.address, _defaultAdmin);
  await contract.deployed();
  return contract;
}

module.exports = {
  setCNR,
  setBaseContract,
};
