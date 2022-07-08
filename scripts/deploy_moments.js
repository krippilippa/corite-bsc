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

async function setMoments(CNR, admin) {
  const Moments = await ethers.getContractFactory("Moments");
  const moments = await Moments.deploy(CNR, admin);
  await moments.deployed();
  await verify(moments.address, [CNR, admin]);
  return moments;
}

async function setMomentsHandler(moments, admin) {
  const MomentsHandler = await ethers.getContractFactory("MomentsHandler");
  const momentsHandler = await MomentsHandler.deploy(moments.address, admin);
  await momentsHandler.deployed();
  await verify(momentsHandler.address, [moments.address, admin]);
  return momentsHandler;
}

async function main() {
  const CNR = "0x254b3682d4b13CcBAF35d1b3142332b89F52FBa9";
  const default_admin = "0x823660e4f9895b3522AFF271A03Fd2E1800acADe";
 // const denWallet = "0x51e6a589dd3d829fbd720b2f8af68f881e2d4fc1";
 // const launchpad = "0x190449C9586a73dA40A839e875Ff55c853dBc2f8";

  let moments = await setMoments(CNR, default_admin);
  let momentsHandler = await setMomentsHandler(moments, default_admin);
  let MINTER = await moments.MINTER();
  let REDEEMER = await moments.REDEEMER();
  await moments.grantRole(MINTER, momentsHandler.address);
  await moments.grantRole(REDEEMER, momentsHandler.address);
//  await momentsHandler.grantRole("0x0000000000000000000000000000000000000000000000000000000000000000", denWallet);
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
