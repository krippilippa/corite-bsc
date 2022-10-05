const hre = require("hardhat");
const fs = require("fs");

const provider = new ethers.providers.JsonRpcProvider(process.env.MORALISMAINNET);
const signer = new ethers.Wallet(process.env.BSCMAINNET_PRIVATE_KEY, provider);

async function main() {
    let info = JSON.parse(fs.readFileSync('scripts/co_at_tge.json'));
    let array = [];
    for (let i = 0; i < info.length; i++) {
        let obj = ethers.utils.defaultAbiCoder.encode(
            ["address", "uint", "uint"],
            [info[i].address, info[i].amount * 1_000_000, 0]
        );
        obj = ethers.utils.arrayify(obj);
        const serverSig = await signer.signMessage(obj);
        const sig = ethers.utils.splitSignature(serverSig);
        const {v, r, s} = sig;
        array.push({ address: info[i].address, amount: info[i].amount * 1_000_000, v, r, s});
    };
    
    const data = JSON.stringify(array, null, 2);
    fs.writeFileSync("scripts/tge_signatures.json", data);
}       

  main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });