const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");

var testCO, CNR, owner, buyer, taxAcc, server, launchpad, MINTER, BURNER, SERVER, ADMIN;

async function setMoments(CNR) {
  const Origins = await ethers.getContractFactory("AWOrigins");
  const origins = await Origins.deploy(CNR.address, launchpad.address, 7000, 500, owner.address);
  await origins.deployed();
  return origins;
}

async function setMomentsHandler(origins) {
  const OriginsHandler = await ethers.getContractFactory("OriginsHandler");
  const originsHandler = await OriginsHandler.deploy(origins.address, 0, 70, owner.address);
  await originsHandler.deployed();
  return originsHandler;
}

describe("Test origins", function () {
  beforeEach(async function () {
    [owner, buyer, taxAcc, server, launchpad] = await ethers.getSigners();
    CNR = await help.setCNR();
    origins = await setMoments(CNR);
    originsHandler = await setMomentsHandler(origins);
    MINTER = await origins.MINTER();
    BURNER = await origins.BURNER();
    SERVER = await originsHandler.SERVER();
    ADMIN = await originsHandler.ADMIN();
    await origins.grantRole(MINTER, originsHandler.address);
    await origins.grantRole(BURNER, originsHandler.address);
    await originsHandler.grantRole(ADMIN, owner.address);
    await originsHandler.grantRole(SERVER, server.address);
    testCO = await help.setTestCO();
    await originsHandler.setCoriteAccount(taxAcc.address);
    await originsHandler.setValidToken(testCO.address, true);
    await testCO.connect(buyer).approve(originsHandler.address, 1000000000);
  });

   it("should buy shares with ERC20 token", async function () {
     const tokenAmount = 200000000;
     const tokenAddress = testCO.address;

     let obj = ethers.utils.defaultAbiCoder.encode(
       ["address", "uint", "address", "uint"],
       [buyer.address, 6900, tokenAddress, tokenAmount]
     );
     const { prefix, v, r, s } = await createSignature(obj);
     await originsHandler.connect(buyer).mintUserPay(6900, tokenAddress, tokenAmount, prefix, v, r, s);

  //  await originsHandler.mintFullGroup(0, buyer.address);
 
    //  await expect(
    //    originsHandler.connect(buyer).mintUserPay(0, tokenAddress, tokenAmount, prefix, v, r, s)
    //  ).to.be.revertedWith("Invalid server signature");
   });

//   it("should claim NFT with sig", async function () {
//     await originsHandler.createGroup(1, 1000, 1);
//     await originsHandler.setOpenMinting(1, true);
//     await originsHandler.connect(buyer).claimNFT(1);
//     expect(await origins.ownerOf(1000000)).to.be.equal(buyer.address);
//   });
});

async function createSignature(obj) {
  obj = ethers.utils.arrayify(obj);
  const prefix = ethers.utils.toUtf8Bytes("\x19Ethereum Signed Message:\n" + obj.length);
  const serverSig = await server.signMessage(obj);
  const sig = ethers.utils.splitSignature(serverSig);
  return { ...sig, prefix };
}
