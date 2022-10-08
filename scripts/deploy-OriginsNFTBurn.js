async function main() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();

  const OriginsNFTBurn = await ethers.getContractFactory("OriginsNFTBurn");
  const originsNFTBurn = await OriginsNFTBurn.deploy(
    "0xA00de4aAe3E1d8726d822CE4A5DA52be4c3FfB28",
    "0x6ee5DA30876E1697cD4Fc217d2A8a44D5A53A77d",
    "0x51E6a589dd3D829FBd720B2f8af68F881E2D4FC1",
    "0x51E6a589dd3D829FBd720B2f8af68F881E2D4FC1"
  );

  await originsNFTBurn.deployed();

  console.log("Burn contract: " + originsNFTBurn.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
