const CNR = "0x5af7DcC0f04D246fA5Ee5aFb61Fb36D246AE84f0";
const mainAdmin = "0x417b53B4F50ef24A0DFf64F9eA0dcE2E76DDE8E0";

async function setBaseERC1155() {
  const Base = await ethers.getContractFactory("Corite_ERC1155");
  const base = await Base.deploy(CNR, mainAdmin);
  await base.deployed();
  return base;
}

async function main() {
  const base = await setBaseERC1155();
  console.log("Contract deployed to:", base.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/deploy-testnet.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet contractAddress paramaters
//contract address: 0x8ff598bc0e793f362ccb39cf8cd0f5eeec088bf3
