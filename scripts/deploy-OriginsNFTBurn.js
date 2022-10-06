async function main() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();

  const TestCO = await ethers.getContractFactory("TestCO");
  const testCO = await TestCO.deploy();

  await testCO.deployed();

  await testCO.faucet();
  console.log("CO: " + testCO.address);

  const Test721 = await ethers.getContractFactory("CoriteMNFT");
  const test721 = await Test721.deploy(
    ethers.constants.AddressZero,
    owner.address
  );

  await test721.deployed();

  console.log("721: " + test721.address);

  const OriginsNFTBurn = await ethers.getContractFactory("OriginsNFTBurn");
  const originsNFTBurn = await OriginsNFTBurn.deploy(
    test721.address,
    testCO.address,
    owner.address,
    "0x51E6a589dd3D829FBd720B2f8af68F881E2D4FC1",
    "0x51E6a589dd3D829FBd720B2f8af68F881E2D4FC1"
  );

  await originsNFTBurn.deployed();

  console.log("contract " + originsNFTBurn.address);

  await test721.grantRole(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BURNER")),
    originsNFTBurn.address
  );

  await testCO.increaseAllowance(originsNFTBurn.address, 10000000);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
