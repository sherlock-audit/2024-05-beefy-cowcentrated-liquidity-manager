pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";
import {BeefyVaultConcLiq} from "contracts/vault/BeefyVaultConcLiq.sol";
import {BeefyVaultConcLiqFactory} from "contracts/vault/BeefyVaultConcLiqFactory.sol";
import {StrategyPassiveManagerUniswap} from "contracts/strategies/uniswap/StrategyPassiveManagerUniswap.sol";
import {StrategyFactory} from "contracts/strategies/StrategyFactory.sol";
import {StratFeeManagerInitializable} from "contracts/strategies/StratFeeManagerInitializable.sol";
import {IStrategyConcLiq} from "contracts/interfaces/beefy/IStrategyConcLiq.sol";
import {UniV3Utils} from "contracts/utils/UniV3Utils.sol";

// Test How a user gets impacted by the strategy
contract ScenarioATest is Test {
    using SafeERC20 for IERC20;

    BeefyVaultConcLiq vault;
    BeefyVaultConcLiqFactory vaultFactory;
    StrategyPassiveManagerUniswap strategy;
    StrategyPassiveManagerUniswap implementation;
    StrategyFactory factory;
    address constant pool = 0xF334F6104A179207DdaCfb41FA3567FEea8595C2;
    address constant token0 = 0x4200000000000000000000000000000000000006;
    address constant token1 = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address constant native = 0x4200000000000000000000000000000000000006 ;
    address constant strategist = 0xb2e4A61D99cA58fB8aaC58Bb2F8A59d63f552fC0;
    address constant beefyFeeRecipient = 0x02Ae4716B9D5d48Db1445814b0eDE39f5c28264B;
    address constant beefyFeeConfig = 0x216EEE15D1e3fAAD34181f66dd0B665f556a638d;
    address constant unirouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant keeper = 0x4fED5491693007f0CD49f4614FFC38Ab6A04B619;
    address constant quoter = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    int24 constant width = 50;
    address constant user = 0x161D61e30284A33Ab1ed227beDcac6014877B3DE;
    uint token0Size = 100 ether;
    uint token1Size = 100 ether;
    bytes tradePath;
    bytes path0;
    bytes path1;

    error NotManager();
    error NotCalm();
    error NotVault();
    error StrategyPaused();

    function setUp() public {

        // Deploy Contracts
        BeefyVaultConcLiq vaultImplementation = new BeefyVaultConcLiq();
        vaultFactory = new BeefyVaultConcLiqFactory(address(vaultImplementation));
        vault = vaultFactory.cloneVault();
        implementation = new StrategyPassiveManagerUniswap();
        factory = new StrategyFactory(native, keeper, beefyFeeRecipient, beefyFeeConfig);
        
        // Set up routing for trade paths
        address[] memory lpToken0ToNative = new address[](2);
        lpToken0ToNative[0] = token0;
        lpToken0ToNative[1] = native;

        address[] memory lpToken1ToNative = new address[](2);
        lpToken1ToNative[0] = token1;
        lpToken1ToNative[1] = native;

        address[] memory tradeRoute = new address[](2);
        tradeRoute[0] = native;
        tradeRoute[1] = token1;

        uint24[] memory fees = new uint24[](1);
        fees[0] = 10000;

        path0 = ""; //routeToPath(lpToken0ToNative, fees);
        path1 = routeToPath(lpToken1ToNative, fees);
        tradePath = routeToPath(tradeRoute, fees);

        // Init the the strategy and vault
        StratFeeManagerInitializable.CommonAddresses memory commonAddresses = StratFeeManagerInitializable.CommonAddresses(
            address(vault),
            unirouter,
            strategist,
            address(factory)
        );

        factory.addStrategy("StrategyPassiveManagerUniswap_v1", address(implementation));
       
        address _strategy = factory.createStrategy("StrategyPassiveManagerUniswap_v1");
        strategy = StrategyPassiveManagerUniswap(_strategy);
        strategy.initialize(
            pool, 
            quoter,
            width,
            path0,
            path1,
            commonAddresses
        );

        vault.initialize(address(strategy), "Moo Vault", "mooVault");

        address _want = vault.want();
        assertEq(_want, pool);

        address[] memory lpToken0Route = strategy.lpToken0ToNative();
        address[] memory lpToken1Route = strategy.lpToken1ToNative();
        assertEq(lpToken0Route.length, 0);
        assertEq(lpToken1Route.length, 2);

    }
/*
    function test_scenario() public {
        address exploiter = vm.addr(1);

        vm.startPrank(user); 
        deal(address(token0), user, token0Size / 10);
        deal(address(token1), user, token1Size / 10);

        IERC20(token0).forceApprove(address(vault), token0Size / 10);
        IERC20(token1).forceApprove(address(vault), token1Size / 10);

        // Test preview and use this as min expected output on deposit. 
        uint _shares = vault.previewDeposit(token0Size / 10, token1Size / 10);
        vault.depositAll(_shares);

        uint256 shares = vault.balanceOf(user);
        console.log("User Shares :", shares);

        // assert the balances of the vault is equal to the deposit amount 
        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, token0Size / 10, 2);
        assertApproxEqAbs(bal1, token1Size / 10, 2);

        console.log("User Bal0:", bal0);
        console.log("User Bal1:", bal1);
        vm.stopPrank();

        vm.startPrank(exploiter);

        deal(address(token0), exploiter, token0Size);
       // deal(address(token1), exploiter, token1Size);

        IERC20(token0).forceApprove(address(unirouter), type(uint256).max);
        IERC20(token1).forceApprove(address(unirouter), type(uint256).max);

        console.log("Exploiter Bal0:", token0Size);

        uint256 balExploiter0;
        uint256 balExploiter1;

        int24 tick = strategy.currentTick();
        (int24 tickLower, int24 tickUpper) = strategy.positionMain();
        console.logInt(tick);
        console.logInt(tickLower);
        console.logInt(tickUpper);

        for (uint i; i < 10; ++i) {

                uint256 token0Bal = IERC20(token0).balanceOf(exploiter);
                UniV3Utils.swap(exploiter, unirouter, tradePath, token0Bal);
                strategy.harvest();

                tick = strategy.currentTick();
                (tickLower, tickUpper) = strategy.positionMain();
                console.log("After Harvest");
                console.log("");
                console.logInt(tick);
                console.logInt(tickLower);
                console.logInt(tickUpper);
                console.log("");

                uint256 token1Bal = IERC20(token1).balanceOf(exploiter);
                UniV3Utils.swap(exploiter, unirouter, path1, token1Bal);
                strategy.harvest();

                balExploiter0 = IERC20(token0).balanceOf(exploiter);
                balExploiter1 = IERC20(token1).balanceOf(exploiter);
                console.log("Exploiter Bal0:", i, balExploiter0);
                console.log("Exploiter Bal1:", i, balExploiter1);
        }

        balExploiter0 = IERC20(token0).balanceOf(exploiter);
        balExploiter1 = IERC20(token1).balanceOf(exploiter);

        console.log("Exploiter Bal0:", balExploiter0);
        console.log("Exploiter Bal1:", balExploiter1);

        vm.stopPrank();

        vm.startPrank(user);

        skip(1  days);
        
        vault.withdrawAll(0,0);
        uint256 user0Bal = IERC20(token0).balanceOf(user);
        uint256 user1Bal = IERC20(token1).balanceOf(user);

        console.log("User Bal0:", user0Bal);    
        console.log("User Bal1:", user1Bal);

        vm.stopPrank();

    }
*/
    // Convert token route to encoded path
    // uint24 type for fees so path is packed tightly
    function routeToPath(
        address[] memory _route,
        uint24[] memory _fee
    ) internal pure returns (bytes memory path) {
        path = abi.encodePacked(_route[0]);
        uint256 feeLength = _fee.length;
        for (uint256 i = 0; i < feeLength; i++) {
            path = abi.encodePacked(path, _fee[i], _route[i+1]);
        }
    }
}