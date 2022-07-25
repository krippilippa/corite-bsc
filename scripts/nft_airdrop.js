//const fs = require("fs");
//const ethers = require("ethers");

const contractAddress = "0x42BEBEB560D69317f4bdC86f1709094434B6579F";

const provider = new ethers.providers.JsonRpcProvider(process.env.MORALISMAINNET);
const signer = new ethers.Wallet(process.env.BSCMAINNET_PRIVATE_KEY, provider);

const abi = [
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "previousAdminRole",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "newAdminRole",
        "type": "bytes32"
      }
    ],
    "name": "RoleAdminChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "sender",
        "type": "address"
      }
    ],
    "name": "RoleGranted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "sender",
        "type": "address"
      }
    ],
    "name": "RoleRevoked",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "DEFAULT_ADMIN_ROLE",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "contract IERC721",
        "name": "_contract",
        "type": "address"
      },
      {
        "internalType": "address[]",
        "name": "_recipients",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_tokenIds",
        "type": "uint256[]"
      }
    ],
    "name": "batchTransfer",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      }
    ],
    "name": "getRoleAdmin",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "grantRole",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "hasRole",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "renounceRole",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "role",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "revokeRole",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes4",
        "name": "interfaceId",
        "type": "bytes4"
      }
    ],
    "name": "supportsInterface",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];
const contract = new ethers.Contract(contractAddress, abi, signer);
const batchSize = 200;
const startReward = 0;
async function main() {

 // let receivers = JSON.parse(fs.readFileSync("pancake-swap.json"));
 const tokenIds = [
  2541,
  2542,
  2543,
  2544,
  2545,
  2546,
  2547,
  2548,
  2549,
  2550,
  2662,
  2663,
  2664,
  2665,
  2666,
  2667,
  2668,
  2669,
  2670,
  2671,
  2753,
  2754,
  2755,
  2756,
  2757,
  2758,
  2759,
  2760,
  2761,
  2762,
  2855,
  2856,
  2857,
  2858,
  2859,
  2860,
  2861,
  2862,
  2863,
  2864,
  2950,
  2951,
  2952,
  2953,
  2954,
  2955,
  2956,
  2957,
  2958,
  2959,
  3044,
  3045,
  3046,
  3047,
  3048,
  3049,
  3050,
  3051,
  3052,
  3053,
  3142,
  3143,
  3144,
  3145,
  3146,
  3147,
  3148,
  3149,
  3150,
  3151,
  3244,
  3245,
  3246,
  3247,
  3248,
  3249,
  3250,
  3251,
  3252,
  3253,
  3337,
  3338,
  3339,
  3340,
  3341,
  3342,
  3343,
  3344,
  3345,
  3346,
  3436,
  3437,
  3438,
  3439,
  3440,
  3441,
  3442,
  3443,
  3444,
  3445
  ]

  const receivers = [
    "0xFB425D430293dbbbC783eF144456E3C76C9a75d8",
    "0x6Cd8A57f2Fd57Bbb258819a128544e6e714EBAFe",
    "0xc2Ac7F93D54dfbf9Bf7E4AeD21F817F2ce598D28",
    "0xDab662aed0410d1C8d32367f77908087BB78A744",
    "0xc2Ac7F93D54dfbf9Bf7E4AeD21F817F2ce598D28",
    "0xFe4263917B9bf35A5eE8d187839Cb27bb4d48C53",
    "0xdc7539f489715f92c6a5c9a72c06dd3a15c09f99",
    "0x5fc245C8A3a7233a100084144da84f3bFf69b334",
    "0xDab662aed0410d1C8d32367f77908087BB78A744",
    "0xca84541D8B8Bf50fd8b042aCFd28B1e390703E20",
    "0x5Bd638E2e9eA925158E32e989F754Ba4A66e6A7b",
    "0x677FCBD5998ecCBa6650F0Ba0087428700923c2B",
    "0x7a38B009F9e176F07978C2E75bab2A5b657cA37a",
    "0x8ef3723B1C813b00E5639d9FEb57f90E1a859C5C",
    "0x6B532334Fa86a82CA1374Fe3E87C04f4cfB21346",
    "0xBE59ef86fb0fde1Ed4C29Faed76BB014a58879e2",
    "0x2416d0Cc95C83F4814E8A9B1ac70244136E9492B",
    "0xb6961237B567eb10c618F674eaeB1eC69Fb0F9d9",
    "0x515bB2C65f70C7a647A802B439e2a0E128ac67df",
    "0xaCA9bE0B7e36E36e32E241A75833b4CF3E4EF11d",
    "0x6c737Fa394Db4b91c8030DF8cAddaf09159BB20C",
    "0x2947B16305717036E8B189A1e630BBB26692Ac98",
    "0xcfb841663408AF488Aa5c009f264FCbaEb948f70",
    "0x983F082A1835B3D7635db74598Ff77Ef6c9B19af",
    "0xAF2f7Af13354137E6150f26cE1B8C747Fa452F8b",
    "0xDA062f47B22E2BDdB3A0f9b662229Ad5ec878d4F",
    "0x735EeEf2188706b6b33f08444eB84774d8628013",
    "0x3471DcDE2C25d1b041F0bC539f44a9Aec6195434",
    "0xd920119121727C5229Ead49C1b2596e0dFE504eE",
    "0xd974af07672FFb07D49f000Fd141609A1d6Eb815",
    "0x9654620E7613c9B9010167CDb93E7B1eA422DE15",
    "0x240a829b963d1e84982A17F2Ff7Bfc9deF8E61D3",
    "0xc3D604C183328fD2DC497cD47F3fC161a727f352",
    "0x94CAE0068765F5219a77beE2642E1e606324f9c6",
    "0x76C5762E65cB28B928466256C680F5342C4Ad234",
    "0x761E065a24d2f25E499E5a3e12c2B4Ba8d7b3027",
    "0xfa3FCB75d0044f20d2A948c8FabbA9873353Efa6",
    "0x0d56557F014cAeE7A2CcE30E7BCB5BCCe46246C1",
    "0xA7DD30b2864DDC29b05CEAaE04E5FD52AEe6109f",
    "0x287035947a36822e478E403044E051FCc4676a44",
    "0xCCCC36b791E6abD8Cc10F2B028b320Fa81335412",
    "0x61265c89eE05bcc8B6c6CE13cB0541Ca9F250a04",
    "0x965c7a331bCDf43ceae73781c4eE726f20805d24",
    "0x4BdC3B5d5004A1409DD62b23a744CFEab3A0CE91",
    "0xf262EF7aA5c59F39dFfC7D84d65957D8693eEeAa",
    "0x6b7541566158b7763D7207800BdfFbF53f794648",
    "0x65e9B33973691e3aD488C9e9871c67C730EF036d",
    "0x72733AC5dd775654Ae3AfE0a3cF88013A632226e",
    "0x17e67E303E49dC902C3a3Bf8f78b62798BC90D75",
    "0x1F8bcA5B3486924bE7aee2D4d00b66bae668CB54",
    "0x1B4E2Dc2831D5C74f246d055C60D5A58B2a6B97a",
    "0x058e0DE2B9694dd6d5bCe9FfD49BE24713ff6E99",
    "0xF90510b26063F787202eA0238f22334a460b1305",
    "0xc79E63a84990de2011A5361d9C31B5b2284A5064",
    "0x677d1901A6d934666E1d70EC92CF2775f9cCB3Ba",
    "0xC0C028809001E7F889CD30EAE0afC0dFe8772c22",
    "0xa497596972f4FcEC430E6D05DF130A2F95405196",
    "0x7282Db4DADd6e11272134c4130894ae5095430C1",
    "0xc771e026346A75bdB4116190e382CeF677fBc07a",
    "0x2416c28AAb5b6EB451B8b82E790a543eA3229a80",
    "0xCE2e67709418B452d8fCd36a502AF27BDE7d4D56",
    "0x69cD4a21639f501DD639226576C4249c1135Dd29",
    "0xA923c7cd9Dda840DE3Dd9d41D284e0c77Ec7FdE2",
    "0xcf75fcCafD2d0879eA6feA5A70f0Bc9C9a69726C",
    "0x720b2878364695aF77C1E7F4977e9594fCD76aA6",
    "0xDFD5f276882aCc982C477f4d220C264d2b707Ac5",
    "0x38554Ec57d1fA6C02C6083aB107041acf7A6BD59",
    "0xCC6304080930816Cb865462E655Ace4AD9fC0147",
    "0x1a133695F7D6A423537207eEDF42f4141C0c4818",
    "0xD379f5114a29B8424406DF9315D1C383021a0A29",
    "0xb18ccB3341a8Df71A81242063EF5E3C4e5905921",
    "0x5c036617E389bD047059D0c7d4C8249708Df3D78",
    "0xd6cEd5BD504dF15FD1CD2d3E39a92d12c0261263",
    "0xAcd0D846197b0fa2CB1CF1127BD972838D2E29d0",
    "0xf5DdC765Bc8370E5dfCa99eeE90AFD957A4e99d0",
    "0x2bF268a2ebd8c09DCA33d74ab3271D14FbD9cd19",
    "0x4f0c24f559D1a3F65Be9F06835c4B196f7C04327",
    "0xa7CB86C25552718b6FCAcdc3D05f4c46777df265",
    "0x3065d3D1AE57Ef5344983f150C51FFE16B9Ec173",
    "0x3f9311a83eB9B1475910C2882328Be08D62707C2",
    "0x62a980bA0b314d233820657941563B25f1d84090",
    "0x3ffC752A535326D50a38aAC9774B41e7bEa67058",
    "0xFb38E0A587D662933D4468dc760CA0314DeC81Fd",
    "0xC0F8aB7741786537845716CDf9c42507F2E53Da4",
    "0x95D80daB0CE3287B4cfb24F43fe84891b3f2Df8E",
    "0x03bB32e6408a120519EFe345F86F1F02BbaF1F67",
    "0xAbe17e3fE9873DDC6827caB0E5F78eF3F2C86104",
    "0x040E3fB3200B6EbC179F2696BeEB8937bd0AEEC6",
    "0x24d87D0C291Bb8B2880A6C066B3ab3E5cfE71B3d",
    "0x20E1353A384F80C9E786aD7f202EDa481850bBCC",
    "0x84BF2224a654e629919162d0ae4cBa01C4bB3Ced",
    "0xC27A94fE420bBfa8C7E97bfB1fDE785B3BB97190",
    "0xdc79c7e0ee222f5e0de7da06ca4f39f25ca174d5",
    "0x23996f568fb910DC508Fbbe83cb013859Bce0895",
    "0x994e35277965854800b4c18875A8E8fFE7c1a800",
    "0x3Ae9B31164367cb80BFAFd6382B3c801d14f0e93",
    "0xE9D4FAE13f69d37b123520c7cdd1cE57727a2d04",
    "0x7418843b488E7cCCcd585785B89FbC44971403F8",
    "0x389C6cA11707a1e088b1707b4278e19A5F4CBc5B",
    "0x9cfDAd32f9127B87FFF03BA323bad8d2251B62bb"
    ]
  
   var allGood = true;
  // for (let i = startReward; i < tokenIds.length; i += batchSize) {
  //   if (allGood) {
  //     const sliceUntil = Math.min(tokenIds.length, i + batchSize);
  //     const transfersToSend = tokenIds.slice(i, sliceUntil);
  //       console.log(transfersToSend);
  //     console.log(`Sending transfers ${i + 1}-${sliceUntil}`);

  const transferTx = await contract.batchTransfer("0xB1C4e4156A4bdDDC4CE7eB05109C677AC91b4228", receivers, tokenIds);

  // wait until the transaction is mined
  let receipt = await transferTx.wait();
  //     if (!receipt.status) {
  //       allGood = false;
  //     }

  //     console.log(`Done Sending transfers ${i + 1}-${sliceUntil}`);
  //   }
  // }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

