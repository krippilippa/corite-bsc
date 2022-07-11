const provider = new ethers.providers.JsonRpcProvider(process.env.MORALIS);
const signer = new ethers.Wallet(process.env.BSCTESTNET_PRIVATE_KEY, provider);

async function setMarketplace(proxy, state, admin) {
  const Market = await ethers.getContractFactory("Marketplace");
  const market = await Market.deploy(proxy.address, state.address, admin);
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

async function main() {
  const default_admin = "";

  let proxy = await setSingleApproveProxy(default_admin);
  let marketState = await setMarketState(default_admin);
  let market = await setMarketplace(proxy, marketState, default_admin);

  console.log("Proxy deployed to:", proxy.address);
  console.log("State deployed to:", marketState.address);
  console.log("Market deployed to:", market.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/deploy-testnet.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet contractAddress paramaters
