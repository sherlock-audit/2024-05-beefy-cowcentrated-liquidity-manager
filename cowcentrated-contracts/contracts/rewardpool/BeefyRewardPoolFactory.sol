// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BeefyRewardPool} from "./BeefyRewardPool.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

// Beefy Reward Pool Proxy Factory
// Minimal proxy pattern for creating new Beefy concentrated liquidity reward pools
contract BeefyRewardPoolFactory {
  using ClonesUpgradeable for address;

  /// @notice Contract template for deploying proxied Beefy Reward Pools
  BeefyRewardPool public instance;

  /// @notice Emitted when a new Beefy Reward Pool is created
  event ProxyCreated(address proxy);

  /** 
   * @notice Constructor initializes the Beefy Reward Pool template instance
   * @param _instance The address of the Beefy Reward Pool template instance
   */
  constructor(address _instance) {
    if (_instance == address(0)) {
      instance = new BeefyRewardPool();
    } else {
      instance = BeefyRewardPool(_instance);
    }
  }

  /**
   * @notice Create a new Beefy Reward Pool as a proxy of the template instance
   * @return A reference to the new proxied Beefy Reward Pool
   */
  function cloneRewardPool(
  ) external returns (BeefyRewardPool) {
    BeefyRewardPool vault = BeefyRewardPool(_cloneContract(address(instance)));
    return vault;
  }

  /**
   * Deploys and returns the address of a clone that mimics the behaviour of `implementation`
   * @param implementation The address of the contract to clone
   * @return The address of the newly created clone
  */
  function _cloneContract(address implementation) private returns (address) {
    address proxy = implementation.clone();
    emit ProxyCreated(proxy);
    return proxy;
  }
}