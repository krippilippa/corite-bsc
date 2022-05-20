require('dotenv').config();
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const BSCTESTNET_PRIVATE_KEY = process.env.BSCTESTNET_PRIVATE_KEY;
const MORALIS = process.env.MORALIS;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",

  networks: {
    hardhat: {
      allowUnlimitedContractSize:true,
    },
    BSCTestnet: {
      url: `${MORALIS}`,
      accounts: [`0x${BSCTESTNET_PRIVATE_KEY}`],
      allowUnlimitedContractSize:true,
    },
    BSCMainnet: {
      url: `${process.env.MORALISMAINNET}`,
      accounts: [`0x${process.env.BSCMAINNET_PRIVATE_KEY}`],
      allowUnlimitedContractSize:true,
    },
  },

  gasReporter: {
    currency: 'USD',
    token: 'BNB',
    gasPriceApi: "https://api.bscscan.com/api?module=proxy&action=eth_gasPrice",
    gasPrice: 7,
    coinmarketcap: "0431b70e-ffff-4061-81b0-fa361384d36c",
    // enabled: (process.env.REPORT_GAS) ? true : false
  },
  etherscan: {
    apiKey: BSCSCAN_API_KEY
  },
};


// npx hardhat size-contracts