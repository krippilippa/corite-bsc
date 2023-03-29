const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_NODE);
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

async function setNftBurner(COAddress, variousAddress, admin) {
    const NftBurner = await ethers.getContractFactory("NFTBurner");
    const nftBurner = await NftBurner.deploy(COAddress, variousAddress, admin);
    await nftBurner.deployed();
    await verify(nftBurner.address, [COAddress, variousAddress, admin]);
    return nftBurner;
}

async function main() {
    const coToken = "0x936B6659Ad0C1b244Ba8Efe639092acae30dc8d6";
    const coVarious = "0x7d2294aDa7E0ea550AFf40F4D5C2b8b6e8921B30";
    const default_admin = "0x823660e4f9895b3522AFF271A03Fd2E1800acADe";
    const denWallet = "0x51e6a589dd3d829fbd720b2f8af68f881e2d4fc1";

    // let moments = await setMoments(CNR, launchpad, default_admin);
    let nftBurner = await setNftBurner(coToken, coVarious, default_admin);
    let ADMIN = await nftBurner.ADMIN();
    await nftBurner.grantRole(ADMIN, denWallet);
    // console.log(moments.address);
    console.log(nftBurner.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/deploy-testnet.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet contractAddress paramaters
