const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const help = require("./test-utils.js");

var testCO, CNR, owner, buyer, taxAcc, server, MINTER, BURNER, cmnft, nftBurner;

async function setNFTBurner(coAddress, cmnft, defaultAdmin) {
    const NftBurner = await ethers.getContractFactory("NFTBurner");
    const nftBurner = await NftBurner.deploy(coAddress, cmnft, defaultAdmin);
    await nftBurner.deployed();
    return nftBurner;
}

describe("Test shares", function () {
    beforeEach(async function () {
        [owner, buyer, taxAcc, server] = await ethers.getSigners();
        CNR = await help.setCNR();
        cmnft = await help.setCoriteMNFT(CNR, owner);
        testCO = await help.setTestCO();
        nftBurner = await setNFTBurner(testCO.address, cmnft.address, owner.address);
        MINTER = await cmnft.MINTER();
        BURNER = await cmnft.BURNER();
        await cmnft.grantRole(BURNER, nftBurner.address);
        await cmnft.grantRole(MINTER, owner.address);
        await cmnft.mint(buyer.address, 1);
        await cmnft.mint(buyer.address, 2);
        await cmnft.mint(buyer.address, 3);
        await testCO.transfer(nftBurner.address, 100000000);
        await nftBurner.changeServerKey(server.address);
    });

    it("should burn tokens for CO", async function () {
        const tokenAmount = 50000000;
        const tokenAddress = testCO.address;

        expect(await cmnft.ownerOf(1)).to.be.equal(buyer.address);
        expect(await cmnft.ownerOf(2)).to.be.equal(buyer.address);
        expect(await cmnft.ownerOf(3)).to.be.equal(buyer.address);

        let obj = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint[]", "uint"],
            [buyer.address, cmnft.address, [1, 2, 3], tokenAmount]
        );
        const { prefix, v, r, s } = await createSignature(obj);
        await nftBurner.connect(buyer).burnAndClaim([1, 2, 3], tokenAmount, prefix, v, r, s);

        await expect(cmnft.ownerOf(1)).to.be.revertedWith("ERC721: invalid token ID");
        await expect(cmnft.ownerOf(2)).to.be.revertedWith("ERC721: invalid token ID");
        await expect(cmnft.ownerOf(3)).to.be.revertedWith("ERC721: invalid token ID");

        expect(await testCO.balanceOf(buyer.address)).to.be.equal(1050000000);
    });
});

async function createSignature(obj) {
    obj = ethers.utils.arrayify(obj);
    const prefix = ethers.utils.toUtf8Bytes("\x19Ethereum Signed Message:\n" + obj.length);
    const serverSig = await server.signMessage(obj);
    const sig = ethers.utils.splitSignature(serverSig);
    return { ...sig, prefix };
}
