const BeefyVaultConcLiq = require("../artifacts/contracts/vault/BeefyVaultConcLiq.sol/BeefyVaultConcLiq.json");
const BeefyVaultConcLiqFactory = require("../artifacts/contracts/vault/BeefyVaultConcLiqFactory.sol/BeefyVaultConcLiqFactory.json");
const StrategyPassiveManagerUniswap = require("../artifacts/contracts/strategies/velodrome/StrategyPassiveManagerVelodrome.sol/StrategyPassiveManagerVelodrome.json");
const StrategyPassiveManagerUniswapFactory = require("../artifacts/contracts/strategies/StrategyFactory.sol/StrategyFactory.json");
const BeefyRewardPool = require("../artifacts/contracts/rewardpool/BeefyRewardPool.sol/BeefyRewardPool.json");
const BeefyRewardPoolFactory = require("../artifacts/contracts/rewardpool/BeefyRewardPoolFactory.sol/BeefyRewardPoolFactory.json");
const { ethers, upgrades, hre } = require("hardhat");
const { addressBook } = require("blockchain-addressbook");

const {
    platforms: {beefyfinance },
    tokens: {
      ETH: { address: ETH },
      USDC: { address: USDC },
      wstETH: { address: wstETH },
      VELOV2: { address: VELOV2 },
    },
  } = addressBook.optimism;

async function main() {

   const vaultFactoryAddress = "0x9B81464a0d183f1565fB0a0Fdd1BB1751FBFfAe6";
   const stratFactoryAddress = "0xd5f70ba6af41c58017b71E710b3080E8fe360392";
   const rewardPoolFactoryAddress = "0x960fD5C8957aC5D59050aF46A482b4ffa72a6E5e";

    const config = {
        name: "Cow Velo ETH-USDC",
        symbol: "cowVeloETH-USDC",
        strategyName: "StrategyPassiveManagerVelodrome_V1",
        pool: "0x3241738149B24C9164dA14Fa2040159FFC6Dd237",
        gauge: "0x8d8d1CdDD5960276A1CDE360e7b5D210C3387948",
        quoter: "0xA2DEcF05c16537C702779083Fe067e308463CE45",
        nftManager: "0xbB5DFE1380333CEE4c2EeBd7202c80dE2256AdF4",
        output: VELOV2,
        native: ETH,
        width: 120,
        strategist: "0xb2e4A61D99cA58fB8aaC58Bb2F8A59d63f552fC0",
        unirouter: "0xF132bdb9573867cD72f2585C338B923F973EB817"
    }

    const outputToNative = ethers.utils.solidityPack(["address", "uint24", "address"], [VELOV2, 200, ETH]);
    const lp0TokenToNative = ethers.utils.solidityPack(["address", "uint24", "address"], [USDC, 100, ETH]);
    const lp1TokenToNative = "0x"; // ethers.utils.solidityPack(["address", "uint24", "address", "uint24", "address"], [USDC, 500, wstETH, 100, ETH]);
    const paths = [outputToNative, lp0TokenToNative, lp1TokenToNative];

    console.log(`Deploying: `, config.name);

    const vaultFactory = await ethers.getContractAt(BeefyVaultConcLiqFactory.abi, vaultFactoryAddress);
    const strategyFactory = await ethers.getContractAt(StrategyPassiveManagerUniswapFactory.abi, stratFactoryAddress);
    const rewardPoolFactory = await ethers.getContractAt(BeefyRewardPoolFactory.abi, rewardPoolFactoryAddress);

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

    let rewardpool = await rewardPoolFactory.callStatic.cloneRewardPool();
    let rewardpoolTx = await rewardPoolFactory.cloneRewardPool();
    rewardpoolTx = await rewardpoolTx.wait();
    rewardpoolTx.status === 1
    ? console.log(`Reward Pool ${rewardpool} is deployed with tx: ${rewardpoolTx.transactionHash}`)
    : console.log(`Reward Pool ${rewardpool} deploy failed with tx: ${rewardpoolTx.transactionHash}`);

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
      config.nftManager,
      config.gauge,
      rewardpool,
      config.output,
      config.width,
      paths,
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

    const rewardPoolContract = await ethers.getContractAt(BeefyRewardPool.abi, rewardpool);
    let rewardInitTx = await rewardPoolContract.initialize(vault, 'RewardPool ' + config.name, 'r' + config.symbol);
    rewardInitTx = await rewardInitTx.wait();
    rewardInitTx === 1
    ? console.log(`Reward Pool Initialized with tx: ${rewardInitTx.transactionHash}`)
    : console.log(`Reward Pool Initialization failed with tx: ${rewardInitTx.transactionHash}`);

    rewardInitTx = await rewardPoolContract.setWhitelist(strat, true);
    rewardInitTx = await rewardInitTx.wait();
    rewardInitTx === 1
    ? console.log(`Reward Pool Set To Whitelist with tx: ${rewardInitTx.transactionHash}`)
    : console.log(`Reward Pool Set To Whitelist failed with tx: ${rewardInitTx.transactionHash}`);

    rewardInitTx = await rewardPoolContract.transferOwnership(beefyfinance.strategyOwner);
    rewardInitTx = await rewardInitTx.wait();
    rewardInitTx === 1
    ? console.log(`Reward Pool Ownership Transfered with tx: ${rewardInitTx.transactionHash}`)
    : console.log(`Reward Pool Ownership Transfered failed with tx: ${rewardInitTx.transactionHash}`);
    
    console.log();
    console.log("Finished deploying Concentrated Liquidity Vault");
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  