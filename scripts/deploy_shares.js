CNR = "0x5af7DcC0f04D246fA5Ee5aFb61Fb36D246AE84f0";
DA = "0x816dE9e81657AC9923E319cf1bb443FDcE06e9A5";

const { ethers, upgrades } = require("hardhat");

async function main() {
    const Shares = await ethers.getContractFactory("Shares");
    const shares = await upgrades.deployProxy(Shares, ["Corite Shares Test", "CO-TEST", CNR, DA], {
        initializer: "initialize",
    });
    await shares.deployed();
    console.log("Shares Contract deployed to:", shares.address);
}

// async function main() {
//     const SharesHandler = await ethers.getContractFactory("SharesHandler");
//     const sharesHandler = await SharesHandler.deploy("0x51E6a589dd3D829FBd720B2f8af68F881E2D4FC1", DA);
//     await sharesHandler.deployed();
//     console.log("SharesHandler Contract deployed to:", sharesHandler.address);
// }

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
