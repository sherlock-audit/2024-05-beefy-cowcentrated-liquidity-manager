const BeefyVaultConcLiq = require("../artifacts/contracts/vault/BeefyVaultConcLiq.sol/BeefyVaultConcLiq.json");
const BeefyVaultConcLiqFactory = require("../artifacts/contracts/vault/BeefyVaultConcLiqFactory.sol/BeefyVaultConcLiqFactory.json");
const StrategyPassiveManagerUniswap = require("../artifacts/contracts/strategies/uniswap/StrategyPassiveManagerUniswap.sol/StrategyPassiveManagerUniswap.json");
const StrategyPassiveManagerUniswapFactory = require("../artifacts/contracts/strategies/StrategyFactory.sol/StrategyFactory.json");
const { ethers, upgrades, hre } = require("hardhat");
const { addressBook } = require("blockchain-addressbook");

const {
    platforms: {beefyfinance },
    tokens: {
      ETH: { address: ETH },
      USDC: { address: USDC },
    //  sUSD:   { address: sUSD },
       ARB: { address: ARB },
   //   mooBIFI: { address: mooBIFI },
    //  OP: { address: OP },
    //  wstETH: { address: wstETH },
      //DEGEN: { address: DEGEN },
    //  arbUSDCe: { address: arbUSDCe },
    },
  } = addressBook.arbitrum;

async function main() {

  const weETH = '0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe';
  const DEGEN = '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed';

   // const COMP = "0x354A6dA3fcde098F8389cad84b0182725c6C91dE";

   const vaultFactoryAddress = "0xB45B92C318277d57328fE09DD5cF6Bd53F4F269B";
   const stratFactoryAddress = "0xB37c7C935CcE547Eb858Fc8F2d8C3B48597f4aE9";

    const config = {
        name: "Cow Uniswap Arbitrum ARB-ETH",
        symbol: "cowUniswapArbitrumARB-ETH",
        strategyName: "StrategyUniswapPassiveManager_V1",
        pool: "0xC6F780497A95e246EB9449f5e4770916DCd6396A",
        quoter: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
        width: 60,
        strategist: "0xb2e4A61D99cA58fB8aaC58Bb2F8A59d63f552fC0",
        unirouter: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
    }

    const lp0TokenToNative = "0x"; //ethers.utils.solidityPack(["address", "uint24", "address"], [USDC, 500, ETH]);
    const lp1TokenToNative = ethers.utils.solidityPack(["address", "uint24", "address"], [ARB, 500, ETH]);

    console.log(`Deploying: `, config.name);

    const vaultFactory = await ethers.getContractAt(BeefyVaultConcLiqFactory.abi, vaultFactoryAddress);
    const strategyFactory = await ethers.getContractAt(StrategyPassiveManagerUniswapFactory.abi, stratFactoryAddress);

    let vault = await vaultFactory.callStatic.cloneVault();
    let tx = await vaultFactory.cloneVault();
    tx = await tx.wait();
    tx.status === 1
    ? console.log(`Vault ${vault} is deployed with tx: ${tx.transactionHash}`)
    : console.log(`Vault ${vault} deploy failed with tx: ${tx.transactionHash}`);

    let strat = await strategyFactory.callStatic.createStrategy(config.strategyName);
    let stratTx = await strategyFactory.createStrategy(config.strategyName);
    stratTx = await stratTx.wait();
    stratTx.status === 1
    ? console.log(`Strat ${strat} is deployed with tx: ${stratTx.transactionHash}`)
    : console.log(`Strat ${strat} deploy failed with tx: ${stratTx.transactionHash}`);

    const vaultContract = await ethers.getContractAt(BeefyVaultConcLiq.abi, vault);
    let vaultInitTx = await vaultContract.initialize(strat, config.name, config.symbol);
    vaultInitTx = await vaultInitTx.wait();
    vaultInitTx === 1
    ? console.log(`Vault Initialized with tx: ${vaultInitTx.transactionHash}`)
    : console.log(`Vault Initialization failed with tx: ${vaultInitTx.transactionHash}`);

    vaultInitTx = await vaultContract.transferOwnership(beefyfinance.vaultOwner);
    vaultInitTx = await vaultInitTx.wait();
    vaultInitTx === 1
    ? console.log(`Ownership Transfered with tx: ${vaultInitTx.transactionHash}`)
    : console.log(`Ownership Transfered failed with tx: ${vaultInitTx.transactionHash}`);

    const constructorArguments = [
      config.pool,
      config.quoter,
      config.width,
      lp0TokenToNative,
      lp1TokenToNative,
      [
        vault,
        config.unirouter,
        config.strategist,
        stratFactoryAddress
      ]
    ];

    const stratContract = await ethers.getContractAt(StrategyPassiveManagerUniswap.abi, strat);
    let stratInitTx = await stratContract.initialize(...constructorArguments);
    stratInitTx = await stratInitTx.wait();
    stratInitTx === 1
    ? console.log(`Strategy Initialized with tx: ${stratInitTx.transactionHash}`)
    : console.log(`Strategy Initialization failed with tx: ${stratInitTx.transactionHash}`);
    
    console.log();
    console.log("Finished deploying Concentrated Liquidity Vault");
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  