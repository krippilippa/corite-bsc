async function setCorite_ERC1155(_cnr, _da){
    const Corite_ERC1155 = await ethers.getContractFactory("Corite_ERC1155");
    const corite_ERC1155 = await Corite_ERC1155.deploy(_cnr, _da);
    await corite_ERC1155.deployed();
    return corite_ERC1155;
  }

  async function setCoriteHandler(_state, _da){
    const CoriteHandler = await ethers.getContractFactory("CoriteHandler");
    const coriteHandler = await CoriteHandler.deploy(_state, _da);
    await coriteHandler.deployed();
    return coriteHandler;
  }
  
  async function main() {
      console.log("HEEEEY")
    const CNR = "0x254b3682d4b13CcBAF35d1b3142332b89F52FBa9";
    const default_admin = "0xBb6A38DBBfd683Da7D5530539F127CdEf73aAf19";
    const Corite_ERC1155 = await setCorite_ERC1155(CNR, default_admin);
    await setCoriteHandler(Corite_ERC1155.address, default_admin);

  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

      // npx hardhat run scripts/deploy-testnet.js --network BSCTestnet
  // npx hardhat verify --network BSCTestnet contractAddress paramaters