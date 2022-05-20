const { ethers } = require("hardhat");

async function setCNR() {
  const ChromiaNetResolver = await ethers.getContractFactory(
    "ChromiaNetResolver"
  );
  const chromiaNetResolver = await ChromiaNetResolver.deploy();
  await chromiaNetResolver.deployed();
  return chromiaNetResolver;
}

async function setStateContract(_cnr, _defaultAdmin) {
  const Contract = await ethers.getContractFactory("Corite_ERC1155");
  const contract = await Contract.deploy(_cnr.address, _defaultAdmin);
  await contract.deployed();
  return contract;
}

async function setHandler(_stateContract, _defaultAdmin) {
  const Contract = await ethers.getContractFactory("CoriteHandler");
  const contract = await Contract.deploy(_stateContract.address, _defaultAdmin);
  await contract.deployed();
  return contract;
}

async function setCoriteMNFT(_cnr, _admin) {
  const CoriteMNFT = await ethers.getContractFactory("CoriteMNFT");
  const coriteMNFT = await CoriteMNFT.deploy(_cnr.address, _admin.address);
  await coriteMNFT.deployed();
  return coriteMNFT;
}

async function setCoriteMNFTHandler(cmft, sap, admin) {
  const CoriteMNFTHandler = await ethers.getContractFactory("CoriteMNFTHandler");
  const coriteMNFTHandler = await CoriteMNFTHandler.deploy(cmft.address, sap.address, admin.address);
  await coriteMNFTHandler.deployed();
  return coriteMNFTHandler;
}

async function setSingleApproveProxy(admin) {
  const SingleApproveProxy = await ethers.getContractFactory("SingleApproveProxy");
  const singleApproveProxy = await SingleApproveProxy.deploy(admin.address);
  await singleApproveProxy.deployed();
  return singleApproveProxy;
}

async function setTestCO() {
  const [owner, admin, artist, backer, server] = await ethers.getSigners();

  const TestCO = await ethers.getContractFactory("TestCO");
  const testCO = await TestCO.deploy();
  await testCO.deployed();
  await testCO.connect(owner).faucet();
  await testCO.connect(admin).faucet();
  await testCO.connect(artist).faucet();
  await testCO.connect(backer).faucet();
  await testCO.connect(server).faucet();
  return testCO;
}

module.exports = {
  setCNR,
  setStateContract,
  setHandler,
  setTestCO,
  setCoriteMNFT,
  setCoriteMNFTHandler,
  setSingleApproveProxy

};
