//const CNR = "0x5af7DcC0f04D246fA5Ee5aFb61Fb36D246AE84f0";
const CNR = 500000000000;
const mainAdmin = "0xBd96Ef063d62Dc7F85b6A4B71CA18B51d0d5048D";

async function setCO() {
 // const Contract = await ethers.getContractFactory("Corite_ERC1155");
  const Contract = await ethers.getContractFactory("CoriteToken");
  const contract = await Contract.deploy(500_000_000_000_000, mainAdmin);
  await contract.deployed();
  return contract;
}

async function main() {
  const contract = await setCO();
  console.log("Contract deployed to:", contract.address);
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
//0x76ba911679CFA9623dEAea9AB86738c83682F485
//0x998dfd2938F77B0431F302E0EAB1eC4010a18A0C
