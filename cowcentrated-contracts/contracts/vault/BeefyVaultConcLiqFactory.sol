// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BeefyVaultConcLiq} from "./BeefyVaultConcLiq.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

// Beefy Finance Vault ConcLiq Proxy Factory
// Minimal proxy pattern for creating new Beefy concentrated liquidity vaults
contract BeefyVaultConcLiqFactory {
  using ClonesUpgradeable for address;

  /// @notice Contract template for deploying proxied Beefy vaults
  BeefyVaultConcLiq public instance;

  /// @notice Emitted when a new Beefy Vault is created
  event ProxyCreated(address proxy);

  /** 
   * @notice Constructor initializes the Beefy Vault template instance
   * @param _instance The address of the Beefy Vault template instance
   */
  constructor(address _instance) {
    if (_instance == address(0)) {
      instance = new BeefyVaultConcLiq();
    } else {
      instance = BeefyVaultConcLiq(_instance);
    }
  }

  /**
   * @notice Create a new Beefy Conc Liq Vault as a proxy of the template instance
   * @return A reference to the new proxied Beefy Vault
   */
  function cloneVault(
  ) external returns (BeefyVaultConcLiq) {
    BeefyVaultConcLiq vault = BeefyVaultConcLiq(_cloneContract(address(instance)));
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