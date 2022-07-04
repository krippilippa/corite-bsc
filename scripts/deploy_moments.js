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

async function setMoments(CNR, admin) {
  const Moments = await ethers.getContractFactory("AWOrigins");
  const moments = await Moments.deploy(CNR, admin, 7000, 500, admin);
  await moments.deployed();
  await verify(moments.address, [CNR, admin, 7000, 500, admin]);
  return moments;
}

async function setMomentsHandler(moments, admin) {
  const MomentsHandler = await ethers.getContractFactory("OriginsHandler");
  const momentsHandler = await MomentsHandler.deploy(moments.address, 0, 70, admin);
  await momentsHandler.deployed();
  await verify(momentsHandler.address, [moments.address, 0, 70, admin]);
  return momentsHandler;
}

async function main() {
  const CNR = "0x5af7DcC0f04D246fA5Ee5aFb61Fb36D246AE84f0";
  const default_admin = "0x816dE9e81657AC9923E319cf1bb443FDcE06e9A5";
  const denWallet = "0x51e6a589dd3d829fbd720b2f8af68f881e2d4fc1";

  let moments = await setMoments(CNR, default_admin);
  let momentsHandler = await setMomentsHandler(moments, default_admin);
  let MINTER = await moments.MINTER();
  await moments.grantRole(MINTER, momentsHandler.address);
  await momentsHandler.grantRole("0x0000000000000000000000000000000000000000000000000000000000000000", denWallet);
  console.log(moments.address);
  console.log(momentsHandler.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/deploy-testnet.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet contractAddress paramaters
