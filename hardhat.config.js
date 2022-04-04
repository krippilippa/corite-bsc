require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const BSC_TESTNET_PRIVATE_KEY = process.env.BSC_TESTNET_PRIVATE_KEY;
const MORALIS = process.env.MORALIS;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",

  networks: {
    BSCTestnet: {
      url: `${MORALIS}`,
      accounts: [`0x${BSC_TESTNET_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: BSCSCAN_API_KEY,
  },
};
