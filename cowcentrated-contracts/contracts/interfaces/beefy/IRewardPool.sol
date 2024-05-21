// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IRewardPool {
    function notifyRewardAmount(address token, uint256 reward, uint256 duration) external;
}