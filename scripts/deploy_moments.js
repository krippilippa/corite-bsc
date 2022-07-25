const provider = new ethers.providers.JsonRpcProvider(process.env.MORALISMAINNET);
const signer = new ethers.Wallet(process.env.BSCMAINNET_PRIVATE_KEY, provider);

async function verify(contract, arr) {
  try {
    await hre.run("verify:verify", { address: contract, constructorArguments: arr });
  } catch (error) {
    if (error.message.includes("Reason: Already Verified")) {
      console.log(contract.address, " contract is already verified!");
    }
  }
}

async function setMoments(CNR, launchpad, admin) {
  const Moments = await ethers.getContractFactory("AWOrigins");
  const moments = await Moments.deploy(CNR, launchpad, 7000, 500, admin);
  await moments.deployed();
  await verify(moments.address, [CNR, launchpad, 7000, 500, admin]);
  return moments;
}

async function setMomentsHandler(admin) {
  const MomentsHandler = await ethers.getContractFactory("OriginsHandler");
  const momentsHandler = await MomentsHandler.deploy("0xB1C4e4156A4bdDDC4CE7eB05109C677AC91b4228", 0, 70, admin);
  await momentsHandler.deployed();
  await verify(momentsHandler.address, ["0xB1C4e4156A4bdDDC4CE7eB05109C677AC91b4228", 0, 70, admin]);
  return momentsHandler;
}

async function main() {
  const CNR = "0x254b3682d4b13CcBAF35d1b3142332b89F52FBa9";
  const default_admin = "0x823660e4f9895b3522AFF271A03Fd2E1800acADe";
  const denWallet = "0x51e6a589dd3d829fbd720b2f8af68f881e2d4fc1";
  const launchpad = "0x190449C9586a73dA40A839e875Ff55c853dBc2f8";
  const server = "0x61ce02dfC2Bd85d0edCC0a557C74db66935E28AA";

 // let moments = await setMoments(CNR, launchpad, default_admin);
  let momentsHandler = await setMomentsHandler(default_admin);
  let SERVER = await momentsHandler.SERVER();
  let ADMIN = await momentsHandler.ADMIN();
  await momentsHandler.grantRole(SERVER, server);
  await momentsHandler.grantRole(ADMIN, server);
  await momentsHandler.grantRole(ADMIN, default_admin);
  await momentsHandler.grantRole(ADMIN, denWallet);
 // console.log(moments.address);
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
