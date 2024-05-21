// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");
const { addressBook } = require("blockchain-addressbook");

const {
    platforms: { beefyfinance },
    tokens: { ETH: {address: ETH}}
  } = addressBook.optimism;

async function main() {
  /*
    const lp0TokenToNative = ethers.utils.solidityPack(["address", "uint24", "address"], [USDC, 500, ETH]);
    const lp1TokenToNative = ethers.utils.solidityPack(["address", "uint24", "address", "uint24", "address"], [USDC, 500, wstETH, 100, ETH]);

    console.log(lp0TokenToNative);
    console.log(lp1TokenToNative);
*//*

    const VaultImplementationContract = await ethers.getContractFactory("BeefyVaultConcLiq");
    const vaultImplementationContract = await VaultImplementationContract.deploy();
    await vaultImplementationContract.deployed();
  
    const vaultImplemenation = vaultImplementationContract.address;
  
    console.log(`Vault Implementation deployed to:`, vaultImplemenation);
  
    const VaultFactoryContract = await ethers.getContractFactory("BeefyVaultConcLiqFactory");
    const vaultFactoryContract = await VaultFactoryContract.deploy(vaultImplemenation);
    await vaultFactoryContract.deployed();

    console.log(`Vault Factory deployed to:`, vaultFactoryContract.address);
  
    const RewardPoolImplementationContract = await ethers.getContractFactory("BeefyRewardPool");
    const rewardPoolImplementationContract = await RewardPoolImplementationContract.deploy();
    await rewardPoolImplementationContract.deployed();

    const rewardPoolImplemenation = rewardPoolImplementationContract.address;

    console.log(`RewardPool Implementation deployed to:`, rewardPoolImplemenation);

    const RewardPoolFactoryContract = await ethers.getContractFactory("BeefyRewardPoolFactory");
    const rewardPoolFactoryContract = await RewardPoolFactoryContract.deploy(rewardPoolImplemenation);
    await rewardPoolFactoryContract.deployed();

    console.log(`RewardPool Factory deployed to:`, rewardPoolFactoryContract.address);
*/
    const ImplementationContract = await ethers.getContractFactory("StrategyPassiveManagerVelodrome");
    const implementationContract = await ImplementationContract.deploy();
    await implementationContract.deployed();
  
    const implemenation = implementationContract.address;
  
    console.log(`Strategy Implementation deployed to:`, implemenation);
  /*
    const FactoryContract = await ethers.getContractFactory("StrategyFactory");
    const factoryContract = await FactoryContract.deploy(ETH, beefyfinance.keeper, beefyfinance.beefyFeeRecipient, beefyfinance.beefyFeeConfig);
    await factoryContract.deployed();

    console.log(`Strategy Factory deployed to:`, factoryContract.address);*/
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  