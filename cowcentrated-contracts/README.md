## Beefy Cowcentrated Contracts Repo

**Beefy's Cowcentrated Liquidity Management Solution**

TL;DR

Beefy's CLM consists of 2 main contracts. The CLM Vault and the Strategy. 
The CLM Vault contract is responsible for handling user interactions and management of user shares. 
The Strategy contract is the LP to the underlying concentrated liquidity pool. It manages the range and does the reward compounding, distribution and fee collection. More information and detail can be found in the documentation below. 

## Documentation

https://docs.beefy.finance/beefy-products/clm

## Usage

### Requirements 
Node Version 18+

### Compile

```shell
$ yarn compile
```

### Test

```shell
Velodrome Test
$ yarn test:velodrome
```


### Coverage

```shell
$ yarn coverage
```

### Deploy

```shell
$ yarn deploy:clm <chain>
```

