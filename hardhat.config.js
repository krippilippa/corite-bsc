require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("@openzeppelin/hardhat-upgrades");

const BSCTESTNET_PRIVATE_KEY = process.env.BSCTESTNET_PRIVATE_KEY;
const RPC_NODE = process.env.RPC_NODE;
const RPC_NODE_MAINNET = process.env.RPC_NODE_MAINNET;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        version: "0.8.4",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },

    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
        BSCTestnet: {
            url: `${RPC_NODE}`,
            accounts: [`0x${BSCTESTNET_PRIVATE_KEY}`],
            allowUnlimitedContractSize: true,
        },

        // ETH: {
        //   url: `${ETH}`,
        //   accounts: [`0x${BSCTESTNET_PRIVATE_KEY}`],
        //   allowUnlimitedContractSize:true,
        // },

        BSCMainnet: {
            url: `${RPC_NODE_MAINNET}`,
            accounts: [`0x${process.env.BSCMAINNET_PRIVATE_KEY}`],
            allowUnlimitedContractSize: true,
        },
    },

    gasReporter: {
        currency: "USD",
        token: "BNB",
        gasPriceApi: "https://api.bscscan.com/api?module=proxy&action=eth_gasPrice",
        gasPrice: 5,
        coinmarketcap: "0431b70e-ffff-4061-81b0-fa361384d36c",
        // enabled: (process.env.REPORT_GAS) ? true : false
    },
    etherscan: {
        apiKey: BSCSCAN_API_KEY,
    },
};

// npx hardhat size-contracts
