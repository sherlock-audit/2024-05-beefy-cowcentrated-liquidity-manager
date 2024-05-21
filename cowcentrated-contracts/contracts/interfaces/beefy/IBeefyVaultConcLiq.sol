// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IBeefyVaultConcLiq {
    function previewDeposit(uint256 _amount0, uint256 _amount1) external view returns (uint256 shares);
    function previewWithdraw(uint256 shares) external view returns (uint256 amount0, uint256 amount1);
    function strategy() external view returns (address);
    function totalSupply() external view returns (uint256);
}