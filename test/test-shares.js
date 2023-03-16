const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const help = require("./test-utils.js");

var testCO, CNR, owner, buyer, taxAcc, server, SERVER, ADMIN, MINT, shares, sharesHandler;

async function setShares(CNR) {
    const Shares = await ethers.getContractFactory("Shares");
    shares = await upgrades.deployProxy(Shares, ["tokenName", "tokenSymbol", CNR.address, owner.address], {
        initializer: "initialize",
    });
    await shares.deployed();
    return shares;
}

async function setSharesHandler() {
    const SharesHandler = await ethers.getContractFactory("SharesHandler");
    const sharesHandler = await SharesHandler.deploy(taxAcc.address, owner.address);
    await sharesHandler.deployed();
    return sharesHandler;
}

describe("Test shares", function () {
    beforeEach(async function () {
        [owner, buyer, taxAcc, server] = await ethers.getSigners();
        CNR = await help.setCNR();
        shares = await setShares(CNR);
        sharesHandler = await setSharesHandler(shares);
        SERVER = await sharesHandler.SERVER();
        ADMIN = await sharesHandler.ADMIN();
        MINT = await shares.MINT();
        await shares.grantRole(MINT, sharesHandler.address);
        await sharesHandler.grantRole(SERVER, server.address);
        testCO = await help.setTestCO();
        await testCO.connect(buyer).approve(sharesHandler.address, 1000000000);
        await testCO.connect(owner).approve(shares.address, 100000000000);
        await shares.connect(owner).issuanceOfShares(100);
    });

    it("should buy shares with ERC20 token", async function () {
        const tokenAmount = 200000000;
        const tokenAddress = testCO.address;

        let obj = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint", "address", "uint", "uint", "address"],
            [
                buyer.address,
                shares.address,
                5,
                tokenAddress,
                tokenAmount,
                await sharesHandler.internalNonce(buyer.address),
                sharesHandler.address,
            ]
        );
        const { prefix, v, r, s } = await createSignature(obj);
        await sharesHandler.connect(buyer).mintUserPay(shares.address, 5, tokenAddress, tokenAmount, prefix, v, r, s);
    });

    it("should read leftToClaim", async function () {
        await sharesHandler.mintForUser(shares.address, [buyer.address], 5);

        await testCO.transfer(shares.address, 1000000000);
        await shares.calculateTokenDistribution(testCO.address);

        await shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [1, 3, 5]);
        let left = await shares.getLeftToClaim(testCO.address, 0, [1, 2, 3, 4, 5]);
        left = left.map((n) => n.toNumber());
        expect(left).to.eql([0, 10000000, 0, 10000000, 0]);
    });
});

async function createSignature(obj) {
    obj = ethers.utils.arrayify(obj);
    const prefix = ethers.utils.toUtf8Bytes("\x19Ethereum Signed Message:\n" + obj.length);
    const serverSig = await server.signMessage(obj);
    const sig = ethers.utils.splitSignature(serverSig);
    return { ...sig, prefix };
}
