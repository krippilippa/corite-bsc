const provider = new ethers.providers.JsonRpcProvider(process.env.MORALIS);
const signer = new ethers.Wallet(process.env.BSCTESTNET_PRIVATE_KEY, provider);

async function verify(contract, arr) {
  try {
    await hre.run("verify:verify", { address: contract, constructorArguments: arr });
  } catch (error) {
    if (error.message.includes("Reason: Already Verified")) {
      console.log(contract.address, " contract is already verified!");
    }
  }
}

async function setMarketplace(proxy, state, admin) {
  const Market = await ethers.getContractFactory("Marketplace");
  const market = await Market.deploy(proxy, state.address, admin);
  await market.deployed();
  await verify(market.address, [proxy, state.address, admin]);
  return market;
}

async function setMarketState(admin) {
  const Market = await ethers.getContractFactory("MarketState");
  const market = await Market.deploy(admin);
  await market.deployed();
  await verify(market.address, [admin]);
  return market;
}

async function setSingleApproveProxy(admin) {
  const SingleApproveProxy = await ethers.getContractFactory("SingleApproveProxy");
  const singleApproveProxy = await SingleApproveProxy.deploy(admin);
  await singleApproveProxy.deployed();
  await verify(singleApproveProxy.address, [admin]);
  return singleApproveProxy;
}

async function main() {
  const default_admin = "0x816dE9e81657AC9923E319cf1bb443FDcE06e9A5";
  const denWallet = "0x51e6a589dd3d829fbd720b2f8af68f881e2d4fc1";

  //let proxy = await setSingleApproveProxy(default_admin);
  let marketState = await setMarketState(default_admin);
  let market = await setMarketplace("0xF8934FE1dc66b5fA6250cbc63515644E276A61b3", marketState, default_admin);

  let HANDLER = await marketState.HANDLER();
  let adminRole = await market.DEFAULT_ADMIN_ROLE();
 // await proxy.grantRole(HANDLER, market.address);
  await marketState.grantRole(HANDLER, market.address);
  await market.grantRole(adminRole, denWallet);

  //console.log("Proxy deployed to:", proxy.address);
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
