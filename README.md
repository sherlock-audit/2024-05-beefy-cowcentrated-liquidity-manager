
# Beefy Cowcentrated Liquidity Manager contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
any EVM-compatible network 
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of <a href="https://github.com/d-xo/weird-erc20" target="_blank" rel="noopener noreferrer">weird tokens</a> you want to integrate?
Standard ERC-20 tokens and USDC/USDT. We will not vault tokens that have a transfer tax. 
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED? If these integrations are trusted, should auditors also assume they are always responsive, for example, are oracles trusted to provide non-stale information, or VRF providers to respond within a designated timeframe?
 We do our own safety review before building on top of underlying protocols. So you can assume them as TRUSTED.
___

### Q: Are there any protocol roles? Please list them and provide whether they are TRUSTED or RESTRICTED, or provide a more comprehensive description of what a role can and can't do/impact.
The "rebalancer" role will be either gelato, which is TRUSTED, or a TRUSTED dev team rebalancer eoa. 
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, arbitrage bots, etc.)?
The is rebalancer that will keep moving the ticks at a certain cadence. Harvesting is permissionless, but Beefy will also run a bot to harvest. 
___

### Q: Are there any hardcoded values that you intend to change before (some) deployments?
No
___

### Q: If the codebase is to be deployed on an L2, what should be the behavior of the protocol in case of sequencer issues (if applicable)? Should Sherlock assume that the Sequencer won't misbehave, including going offline?
Can assume the sequencer will not misbehave. 
___

### Q: Should potential issues, like broken assumptions about function behavior, be reported if they could pose risks in future integrations, even if they might not be an issue in the context of the scope? If yes, can you elaborate on properties/invariants that should hold?
Yes
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
We know that swapping our fees via the router can cause loss due to lack of slippage/priceProtection, it is a known issue. We have mitigation in place via frequent harvest, harvesting via private rpcs, and a swapper oracle which will be implemented in the future. 
___

### Q: We will report issues where the core protocol functionality is inaccessible for at least 7 days. Would you like to override this value?
No
___

### Q: Please list any relevant protocol resources.
https://docs.beefy.finance/beefy-products/clm
___



# Audit scope


[cowcentrated-contracts @ e1e5bc81c830700501624d6b2643b2e8ad5ecb91](https://github.com/beefyfinance/cowcentrated-contracts/tree/e1e5bc81c830700501624d6b2643b2e8ad5ecb91)
- [cowcentrated-contracts/contracts/interfaces/beefy/IFeeConfig.sol](cowcentrated-contracts/contracts/interfaces/beefy/IFeeConfig.sol)
- [cowcentrated-contracts/contracts/interfaces/velodrome/INftPositionManager.sol](cowcentrated-contracts/contracts/interfaces/velodrome/INftPositionManager.sol)
- [cowcentrated-contracts/contracts/interfaces/velodrome/IVeloRouter.sol](cowcentrated-contracts/contracts/interfaces/velodrome/IVeloRouter.sol)
- [cowcentrated-contracts/contracts/strategies/StratFeeManagerInitializable.sol](cowcentrated-contracts/contracts/strategies/StratFeeManagerInitializable.sol)
- [cowcentrated-contracts/contracts/strategies/velodrome/StrategyPassiveManagerVelodrome.sol](cowcentrated-contracts/contracts/strategies/velodrome/StrategyPassiveManagerVelodrome.sol)
- [cowcentrated-contracts/contracts/utils/LiquidityAmounts.sol](cowcentrated-contracts/contracts/utils/LiquidityAmounts.sol)
- [cowcentrated-contracts/contracts/utils/Path.sol](cowcentrated-contracts/contracts/utils/Path.sol)
- [cowcentrated-contracts/contracts/utils/TickMath.sol](cowcentrated-contracts/contracts/utils/TickMath.sol)
- [cowcentrated-contracts/contracts/utils/TickUtils.sol](cowcentrated-contracts/contracts/utils/TickUtils.sol)
- [cowcentrated-contracts/contracts/utils/VeloSwapUtils.sol](cowcentrated-contracts/contracts/utils/VeloSwapUtils.sol)


