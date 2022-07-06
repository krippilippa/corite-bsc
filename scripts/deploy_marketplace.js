const provider = new ethers.providers.JsonRpcProvider(process.env.MORALIS);
const signer = new ethers.Wallet(process.env.BSCTESTNET_PRIVATE_KEY, provider);

async function setMarketplace(state, admin) {
  const Market = await ethers.getContractFactory("Marketplace");
  const market = await Market.deploy("0xF8934FE1dc66b5fA6250cbc63515644E276A61b3", state.address, admin);
  await market.deployed();
  return market;
}

async function setMarketState(admin) {
  const Market = await ethers.getContractFactory("MarketState");
  const market = await Market.deploy(admin);
  await market.deployed();
  return market;
}

async function setSingleApproveProxy(admin) {
  const SingleApproveProxy = await ethers.getContractFactory("SingleApproveProxy");
  const singleApproveProxy = await SingleApproveProxy.deploy(admin);
  await singleApproveProxy.deployed();
  return singleApproveProxy;
}

const proxy = new ethers.Contract(
  "0xF8934FE1dc66b5fA6250cbc63515644E276A61b3",
  require("../artifacts/contracts/SingleApproveProxy.sol/SingleApproveProxy.json").abi,
  signer
);

async function main() {
  const default_admin = "0x816dE9e81657AC9923E319cf1bb443FDcE06e9A5";
  const denWallet = "0x51e6a589dd3d829fbd720b2f8af68f881e2d4fc1";

  // let proxy = await setSingleApproveProxy(default_admin);
  //   let marketState = await setMarketState(default_admin);
  //   let market = await setMarketplace(marketState, default_admin);
  //   let MARKET_ADMIN = await market.MARKET_ADMIN();
  //   let HANDLER = await marketState.HANDLER();
  //   await marketState.grantRole(HANDLER, market.address);
  await proxy.grantRole(
    "0xf40ec076ff2e3a403e1c18632267861d39085e7f359ca5665846f335632cf819",
    "0xe0b5cacf2e10d1ee96df6259f6ec3563ab7fcb47"
  );
  //   await market.grantRole(MARKET_ADMIN, denWallet);
  // //  console.log("Proxy deployed to:", proxy.address);
  //   console.log("State deployed to:", marketState.address);
  //   console.log("Market deployed to:", market.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/deploy-testnet.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet contractAddress paramaters
