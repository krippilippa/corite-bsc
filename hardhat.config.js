require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require('hardhat-contract-sizer');
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
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    BSCTestnet: {
      url: `${MORALIS}`,
      accounts: [`0x${BSC_TESTNET_PRIVATE_KEY}`],
      allowUnlimitedContractSize: true,
    },
    BSCMainnet: {
      url: `${process.env.MORALISMAINNET}`,
      accounts: [`0x${process.env.BSCMAINNET_PRIVATE_KEY}`],
      allowUnlimitedContractSize:true,
    },
  },
  etherscan: {
    apiKey: BSCSCAN_API_KEY,
  },
};
