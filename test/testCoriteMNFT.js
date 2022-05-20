const { expect } = require("chai");
const { ethers } = require("hardhat");
const help = require("./test-utils.js");
const firstCampaignId = "100000000000000000000000000000000000000000000000000000000000000000001";

var owner, admin, artist, backer;

describe("Test create campaign", function () {
  var CNR, sap, cmnft, ch;

  beforeEach(async function () {
    [owner, corite, user] = await ethers.getSigners();
    CNR = await help.setCNR();
    sap = await help.setSingleApproveProxy(owner);
    cmnft = await help.setCoriteMNFT(CNR, owner);
    ch = await help.setCoriteMNFTHandler(cmnft, sap, owner);
  });

  it("should create group", async function () {
    let MINTER = await cmnft.MINTER();
    await cmnft.grantRole(MINTER, ch.address);
    let ADMIN = await ch.ADMIN();
    await ch.grantRole(ADMIN, owner.address);
    let HANDLER = await sap.HANDLER();
    await sap.grantRole(HANDLER, ch.address);
    await ch.updateCoriteAccount(corite.address);
    await ch.updateServer(owner.address);
    await ch.createGroup(1000);

    const totalPrice = ethers.utils.parseEther("0.5");
    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "uint", "address", "uint", "uint"],
      [owner.address, 1000, ethers.constants.AddressZero, totalPrice, 0]
    );
    const { prefix, v, r, s } = await createSignature(obj);

    await sap.setTokenApproved(ethers.constants.AddressZero, true);

    await ch.mintUserPay(1000, ethers.constants.AddressZero, totalPrice, prefix, v, r, s, {
        value: totalPrice,
      });
  });
});

async function createSignature(obj) {
    obj = ethers.utils.arrayify(obj);
    const prefix = ethers.utils.toUtf8Bytes("\x19Ethereum Signed Message:\n" + obj.length);
    const serverSig = await owner.signMessage(obj);
    const sig = ethers.utils.splitSignature(serverSig);
    return { ...sig, prefix };
  }

//   function mintUserPay(
//     uint _group,
//     address _token,
//     uint _price,
//     bytes calldata _prefix,
//     uint8 _v,
//     bytes32 _r,
//     bytes32 _s
// ) external {
//     bytes memory message = abi.encode(msg.sender, _group, _token, _price, internalNonce[msg.sender]);
//     bytes32 m = keccak256(abi.encodePacked(_prefix, message));
//     require(ecrecover(m, _v, _r, _s) == serverPubKey, "Signature invalid");
//     internalNonce[msg.sender]++;
//     require(groupOpen[_group], "Minting of group is closed");
//     singleApproveProxy.transferFrom(_token, msg.sender, coriteAccount, _price);
//     _mint(msg.sender, _group);
// }