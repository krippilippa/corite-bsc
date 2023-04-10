const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const help = require("./test-utils.js");

var testCO, CNR, owner, buyer, taxAcc, server, SERVER, ADMIN, MINT, shares, sharesHandler;
let zeroAddress = ethers.constants.AddressZero;

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

// describe("Test shares", function () {
//     beforeEach(async function () {
//         [owner, buyer, taxAcc, server] = await ethers.getSigners();
//         CNR = await help.setCNR();
//         shares = await setShares(CNR);
//         sharesHandler = await setSharesHandler(shares);
//         SERVER = await sharesHandler.SERVER();
//         ADMIN = await sharesHandler.ADMIN();
//         MINT = await shares.MINT();
//         await shares.grantRole(MINT, sharesHandler.address);
//         await sharesHandler.grantRole(SERVER, server.address);
//         testCO = await help.setTestCO();
//         await testCO.connect(buyer).approve(sharesHandler.address, 1000000000);
//         await testCO.connect(owner).approve(shares.address, 100000000000);
//         await shares.connect(owner).issuanceOfShares(100);
//     });

//     it("should mint shares for users as an admin", async function () {
//         await sharesHandler.connect(owner).mintForUser(shares.address, [buyer.address], 5);
//         const buyerBalance = await shares.balanceOf(buyer.address);
//         expect(buyerBalance.toNumber()).to.equal(5);
//     });

//     it("should not mint shares for users as a non-admin", async function () {
//         await expect(sharesHandler.connect(buyer).mintForUser(shares.address, [buyer.address], 5)).to.be.revertedWith(
//             "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42"
//         );
//     });

//     it("should buy shares with ERC20 token", async function () {
//         const tokenAmount = 200000000;
//         const tokenAddress = testCO.address;

//         let obj = ethers.utils.defaultAbiCoder.encode(
//             ["address", "address", "uint", "address", "uint", "uint", "address"],
//             [
//                 buyer.address,
//                 shares.address,
//                 5,
//                 tokenAddress,
//                 tokenAmount,
//                 await sharesHandler.internalNonce(buyer.address),
//                 sharesHandler.address,
//             ]
//         );
//         const { prefix, v, r, s } = await createSignature(obj);
//         await sharesHandler.connect(buyer).mintUserPay(shares.address, 5, tokenAddress, tokenAmount, prefix, v, r, s);
//     });

//     it("should buy shares with native token", async function () {
//         const tokenAmount = ethers.utils.parseEther("0.2");
//         const tokenAddress = ethers.constants.AddressZero;

//         let obj = ethers.utils.defaultAbiCoder.encode(
//             ["address", "address", "uint", "address", "uint", "uint", "address"],
//             [
//                 buyer.address,
//                 shares.address,
//                 5,
//                 tokenAddress,
//                 tokenAmount,
//                 await sharesHandler.internalNonce(buyer.address),
//                 sharesHandler.address,
//             ]
//         );
//         const { prefix, v, r, s } = await createSignature(obj);
//         await sharesHandler
//             .connect(buyer)
//             .mintUserPay(shares.address, 5, tokenAddress, tokenAmount, prefix, v, r, s, { value: tokenAmount });

//         const buyerBalance = await shares.balanceOf(buyer.address);
//         expect(buyerBalance.toNumber()).to.equal(5);
//     });

//     it("should pause and unpause SharesHandler", async function () {
//         await sharesHandler.connect(owner).pauseHandler();
//         expect(await sharesHandler.paused()).to.be.true;

//         await sharesHandler.connect(owner).unpauseHandler();
//         expect(await sharesHandler.paused()).to.be.false;
//     });

//     it("should mint shares for multiple users", async function () {
//         const users = [buyer.address, taxAcc.address];
//         const amount = 7;

//         await sharesHandler.connect(owner).mintForUser(shares.address, users, amount);

//         const buyerBalance = await shares.balanceOf(buyer.address);
//         const taxAccBalance = await shares.balanceOf(taxAcc.address);

//         expect(buyerBalance.toNumber()).to.equal(amount);
//         expect(taxAccBalance.toNumber()).to.equal(amount);
//     });

//     it("should fail to buy shares with incorrect token amount", async function () {
//         const tokenAmount = 200000000;
//         const incorrectTokenAmount = 150000000;
//         const tokenAddress = testCO.address;

//         let obj = ethers.utils.defaultAbiCoder.encode(
//             ["address", "address", "uint", "address", "uint", "uint", "address"],
//             [
//                 buyer.address,
//                 shares.address,
//                 5,
//                 tokenAddress,
//                 tokenAmount,
//                 await sharesHandler.internalNonce(buyer.address),
//                 sharesHandler.address,
//             ]
//         );
//         const { prefix, v, r, s } = await createSignature(obj);

//         await expect(
//             sharesHandler
//                 .connect(buyer)
//                 .mintUserPay(shares.address, 5, tokenAddress, incorrectTokenAmount, prefix, v, r, s)
//         ).to.be.revertedWith("Invalid server signature");
//     });

//     it("should fail to buy shares with same server signature", async function () {
//         const tokenAmount = 200000000;
//         const tokenAddress = testCO.address;

//         let obj = ethers.utils.defaultAbiCoder.encode(
//             ["address", "address", "uint", "address", "uint", "uint", "address"],
//             [
//                 buyer.address,
//                 shares.address,
//                 5,
//                 tokenAddress,
//                 tokenAmount,
//                 await sharesHandler.internalNonce(buyer.address),
//                 sharesHandler.address,
//             ]
//         );
//         const { prefix, v, r, s } = await createSignature(obj);

//         await sharesHandler.connect(buyer).mintUserPay(shares.address, 5, tokenAddress, tokenAmount, prefix, v, r, s);

//         await expect(
//             sharesHandler.connect(buyer).mintUserPay(shares.address, 5, tokenAddress, tokenAmount, prefix, v, r, s)
//         ).to.be.revertedWith("Invalid server signature");
//     });

//     it("should fail when trying to claim earnings with invalid indices", async function () {
//         await sharesHandler.mintForUser(shares.address, [buyer.address], 5);

//         await testCO.transfer(shares.address, 1000000000);
//         await shares.calculateTokenDistribution(testCO.address);

//         await expect(
//             shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [0, 3, 5])
//         ).to.be.revertedWith("ERC721: invalid token ID");
//     });

//     it("should fail to mint shares when not called by SharesHandler", async function () {
//         await expect(shares.connect(owner).mint(buyer.address, 5)).to.be.revertedWith(
//             "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xfdf81848136595c31bb5f76217767372bc4bf906663038eb38381131ea27ecba"
//         );
//     });

//     it("should fail to issue shares when not called by ADMIN", async function () {
//         await expect(shares.connect(buyer).issuanceOfShares(100)).to.be.revertedWith(
//             "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42"
//         );
//     });

//     it("should fail to change the tax account in SharesHandler by non-ADMIN", async function () {
//         const newTaxAcc = ethers.Wallet.createRandom();
//         await expect(sharesHandler.connect(buyer).setCoriteAccount(newTaxAcc.address)).to.be.revertedWith(
//             "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42"
//         );
//     });

//     it("should read leftToClaim", async function () {
//         await sharesHandler.mintForUser(shares.address, [buyer.address], 5);

//         await testCO.transfer(shares.address, 1000000000);
//         await shares.calculateTokenDistribution(testCO.address);

//         await shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [1, 3, 5]);
//         let left = await shares.getLeftToClaim(testCO.address, 0, [1, 2, 3, 4, 5]);
//         left = left.map((n) => n.toNumber());
//         expect(left).to.eql([0, 10000000, 0, 10000000, 0]);
//     });
// });

describe("Test claim periods", function () {
    beforeEach(async function () {
        [owner, buyer, taxAcc, server] = await ethers.getSigners();
        CNR = await help.setCNR();
        shares = await setShares(CNR);
        testCO = await help.setTestCO();
        await testCO.connect(owner).approve(shares.address, 1000000000);
        await shares.setPeriodAndDelay(60, 10);
        await shares.connect(owner).issuanceOfShares(100);
    });

    it("should add earnings to first period", async function () {
        let COAmount = 100000000;
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        let earnings = (await shares.token(testCO.address, 0)).earningsAccountedFor.toNumber();

        expect(earnings).to.be.equal(COAmount);
    });

    it("should add native earnings to first period", async function () {
        let amount = ethers.utils.parseEther("1");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        let earnings = (await shares.token(zeroAddress, 0)).earningsAccountedFor;
        expect(earnings).to.be.equal(amount);
    });

    it("should add earnings to second period", async function () {
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        let COAmount = 100000000;
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        let earnings = (await shares.token(testCO.address, 1)).earningsAccountedFor.toNumber();
        let earnings0 = (await shares.token(testCO.address, 0)).earningsAccountedFor.toNumber();

        expect(earnings).to.be.equal(COAmount);
        expect(earnings0).to.be.equal(0);
    });

    it("should add native earnings to second period", async function () {
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        let amount = ethers.utils.parseEther("1");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        let earnings = (await shares.token(zeroAddress, 1)).earningsAccountedFor;
        let earnings0 = (await shares.token(zeroAddress, 0)).earningsAccountedFor;

        expect(earnings).to.be.equal(amount);
        expect(earnings0).to.be.equal(0);
    });

    it("should add previous earnings to retroActiveTotals", async function () {
        let COAmount = 100000000;
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        let earnings = (await shares.token(testCO.address, 2)).earningsAccountedFor.toNumber();
        let retroActiveTotals = (await shares.retroactiveTotals(testCO.address)).toNumber();

        expect(earnings).to.be.equal(COAmount);
        expect(retroActiveTotals).to.be.equal(COAmount * 2);
    });

    it("should add previous native earnings to retroActiveTotals", async function () {
        let amount = ethers.utils.parseEther("1");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        let earnings = (await shares.token(zeroAddress, 2)).earningsAccountedFor;
        let retroActiveTotals = await shares.retroactiveTotals(zeroAddress);

        expect(earnings).to.be.equal(amount);
        expect(retroActiveTotals).to.be.equal(ethers.utils.parseEther("2"));
    });
});

describe("Test claimEarnings", function () {
    beforeEach(async function () {
        [owner, buyer, taxAcc, server] = await ethers.getSigners();
        CNR = await help.setCNR();
        shares = await setShares(CNR);
        testCO = await help.setTestCO();
        MINT = await shares.MINT();
        await shares.grantRole(MINT, owner.address);
        await testCO.approve(shares.address, 1000000000);
        await shares.setPeriodAndDelay(60, 10);
        await shares.issuanceOfShares(100);
        await shares.mint(buyer.address, 10);
    });

    it("should claim earnings in current period", async function () {
        let COAmount = 100000000;
        let initialBalance = (await testCO.balanceOf(buyer.address)).toNumber();
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        await shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [1, 2, 3, 4, 5]);
        let newBalance = (await testCO.balanceOf(buyer.address)).toNumber();
        expect(newBalance).to.be.equal(initialBalance + 5000000);
        let earningsLeft = (await shares.token(testCO.address, 0)).earningsAccountedFor.toNumber();
        expect(earningsLeft).to.be.equal(COAmount - 5000000);
    });

    it("should claim native earnings in current period", async function () {
        let amount = ethers.utils.parseEther("1");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        await shares.connect(buyer).claimEarningsNative(0, buyer.address, [1, 2, 3, 4, 5]);
        let earningsLeft = (await shares.token(zeroAddress, 0)).earningsAccountedFor;
        expect(earningsLeft).to.be.equal(ethers.utils.parseEther("0.95"));
    });

    it("should claim earnings in previous period", async function () {
        let COAmount = 100000000;
        let initialBalance = (await testCO.balanceOf(buyer.address)).toNumber();
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);
        await shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [1, 2, 3, 4, 5]);
        let newBalance = (await testCO.balanceOf(buyer.address)).toNumber();
        expect(newBalance).to.be.equal(initialBalance + 5000000);
        let retroActiveTotals = (await shares.retroactiveTotals(testCO.address)).toNumber();
        expect(retroActiveTotals).to.be.equal(COAmount - 5000000);
    });

    it("should claim native earnings in previous period", async function () {
        let amount = ethers.utils.parseEther("1");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        await ethers.provider.send("evm_increaseTime", [61]);
        await ethers.provider.send("evm_mine");
        await owner.sendTransaction({
            to: shares.address,
            value: amount,
        });
        await shares.calculateTokenDistribution(zeroAddress);
        await shares.connect(buyer).claimEarningsNative(0, buyer.address, [1, 2, 3, 4, 5]);
        let retroActiveTotals = await shares.retroactiveTotals(zeroAddress);
        expect(retroActiveTotals).to.be.equal(ethers.utils.parseEther("0.95"));
    });
});

describe("Test calculateTokenDistribution", function () {
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
        await sharesHandler.mintForUser(shares.address, [buyer.address], 10);
    });

    it("should update leftToClaim", async function () {
        await testCO.transfer(shares.address, 1000000000);
        await shares.calculateTokenDistribution(testCO.address);

        await shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [1, 3, 5]);
        let left = await shares.getLeftToClaim(testCO.address, 0, [1, 2, 3, 4, 5]);
        left = left.map((n) => n.toNumber());
        expect(left).to.eql([0, 10000000, 0, 10000000, 0]);
    });

    it("should calculateTokenDistribution for multiple tokens", async function () {
        let testCO2 = await help.setTestCO();
        await testCO2.connect(buyer).approve(sharesHandler.address, 1000000000);
        await testCO2.connect(owner).approve(shares.address, 100000000000);

        await testCO.transfer(shares.address, 1000000000);
        await testCO2.transfer(shares.address, 1000000000);
        let expectedShareEarnings = 1000000000 / 100;
        await shares.calculateTokensDistribution([testCO.address, testCO2.address]);

        let shareClaims1 = (await shares.token(testCO.address, 0)).shareEarnings.toNumber();
        let shareClaims2 = (await shares.token(testCO2.address, 0)).shareEarnings.toNumber();
        expect(shareClaims1).to.eql(expectedShareEarnings);
        expect(shareClaims2).to.eql(expectedShareEarnings);
    });
});

describe("Test flush", function () {
    beforeEach(async function () {
        [owner, buyer, taxAcc, server] = await ethers.getSigners();
        CNR = await help.setCNR();
        shares = await setShares(CNR);
        MINT = await shares.MINT();
        await shares.grantRole(MINT, owner.address);
        testCO = await help.setTestCO();
        await testCO.approve(shares.address, 1000000000);
        await shares.setPeriodAndDelay(60, 10);
        await shares.issuanceOfShares(100);
        await shares.mint(buyer.address, 10);
    });
    it("should fail if period is not flushable", async () => {
        await testCO.transfer(shares.address, 100000000);
        await shares.calculateTokenDistribution(testCO.address);
        await expect(shares.flush(0, [testCO.address])).to.be.revertedWith(
            "Not Possible to flush this deposit period yet."
        );
    });

    it("should flush a period successfully", async () => {
        const initialBalance = (await testCO.balanceOf(owner.address)).toNumber();
        let COAmount = 100000000;
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);

        await shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [1, 2, 3, 4, 5]);

        let claimedAmount = 5000000;
        // Wait for the period to be flushable
        await ethers.provider.send("evm_increaseTime", [71]);
        await ethers.provider.send("evm_mine");

        // await testCO.connect(owner).transfer(shares.address, 100000000);
        // await shares.calculateTokenDistribution(testCO.address);

        await shares.flush(0, [testCO.address]);
        await expect(
            shares.connect(buyer).claimEarnings(testCO.address, 0, buyer.address, [6, 7, 8, 9, 10])
        ).to.be.revertedWith("Nothing to claim or flushed");

        const finalBalance = (await testCO.balanceOf(owner.address)).toNumber();

        expect(finalBalance).to.equal(initialBalance - claimedAmount);
    });

    it("should emit Flush event", async () => {
        let COAmount = 100000000;
        await testCO.transfer(shares.address, COAmount);
        await shares.calculateTokenDistribution(testCO.address);

        // Wait for the period to be flushable
        await ethers.provider.send("evm_increaseTime", [71]);
        await ethers.provider.send("evm_mine");

        await expect(shares.flush(0, [testCO.address]))
            .to.emit(shares, "Flush")
            .withArgs(testCO.address, 0);
    });

    it("Supports interface", async function () {
        expect(await shares.supportsInterface("0x5b5e139f")).to.be.true;
    });

    it("Can get metadata url", async function () {
        let tokenId = 3;
        let url = await shares.tokenURI(tokenId);
        let expected = `https://chromia.net/oe/bsc/${shares.address.toLowerCase()}/${tokenId}`;

        expect(url).to.be.equal(expected);
    });

    it("Can't get metadata url for nonexistent token", async function () {
        await expect(shares.tokenURI(0)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
    });
});

describe("Test token limitations", function () {
    beforeEach(async function () {
        [owner, buyer, taxAcc, server] = await ethers.getSigners();
        CNR = await help.setCNR();
        shares = await setShares(CNR);
        MINT = await shares.MINT();
        await shares.grantRole(MINT, owner.address);
        testCO = await help.setTestCO();
        await testCO.connect(owner).approve(shares.address, 100000000000);
        await shares.issuanceOfShares(10);
        await shares.mint(buyer.address, 10);
    });

    it("should fail on transferBlocked", async function () {
        await shares.setTransferBlocked(true);
        await expect(shares.connect(buyer).transferFrom(buyer.address, taxAcc.address, 1)).to.be.revertedWith(
            "Transfers are currently blocked"
        );
        await shares.setTransferBlocked(false);
        await shares.connect(buyer).transferFrom(buyer.address, taxAcc.address, 1);
        expect(await shares.ownerOf(1)).to.be.equal(taxAcc.address);
    });

    it("should fail on WL required", async function () {
        await shares.setTransferWL(true);
        await expect(shares.connect(buyer).transferFrom(buyer.address, taxAcc.address, 1)).to.be.revertedWith(
            "Invalid token transfer"
        );
        await shares.addToWhitelist([buyer.address]);
        await expect(shares.connect(buyer).transferFrom(buyer.address, taxAcc.address, 1)).to.be.revertedWith(
            "Invalid token transfer"
        );
        await shares.addToWhitelist([taxAcc.address]);
        await shares.connect(buyer).transferFrom(buyer.address, taxAcc.address, 1);
        await shares.setTransferWL(false);
        await shares.connect(taxAcc).transferFrom(taxAcc.address, owner.address, 1);
        expect(await shares.ownerOf(1)).to.be.equal(owner.address);
    });

    it("should burn when burning enabled", async function () {
        await expect(shares.connect(buyer).burnBatch([1, 2, 3, 4, 5])).to.be.revertedWith("Burning shares is disabled");
        await shares.setBurnEnabled(true);
        await expect(shares.connect(owner).burnBatch([1, 2, 3, 4, 5])).to.be.revertedWith("Invalid token owner");
        await shares.connect(buyer).burnBatch([1, 2, 3, 4, 5]);
        await expect(shares.ownerOf(5)).to.be.revertedWith("ERC721: invalid token ID");
    });
});
async function createSignature(obj) {
    obj = ethers.utils.arrayify(obj);
    const prefix = ethers.utils.toUtf8Bytes("\x19Ethereum Signed Message:\n" + obj.length);
    const serverSig = await server.signMessage(obj);
    const sig = ethers.utils.splitSignature(serverSig);
    return { ...sig, prefix };
}
