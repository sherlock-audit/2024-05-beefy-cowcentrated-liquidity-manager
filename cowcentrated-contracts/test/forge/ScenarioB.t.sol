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
contract ScenarioBTest is Test {
    using SafeERC20 for IERC20;

    BeefyVaultConcLiq vault;
    BeefyVaultConcLiqFactory vaultFactory;
    StrategyPassiveManagerUniswap strategy;
    StrategyPassiveManagerUniswap implementation;
    BeefyVaultConcLiq vault2;
    StrategyPassiveManagerUniswap strategy2;
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
    uint token0Size = 10 ether;
    uint token1Size = 280500 ether;
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

        vault2 = vaultFactory.cloneVault();
        address _strategy2 = factory.createStrategy("StrategyPassiveManagerUniswap_v1");
        strategy2 = StrategyPassiveManagerUniswap(_strategy2);

        vault2.initialize(address(strategy2), "Moo Vault2", "mooVault2");

         // Init the the strategy and vault
        commonAddresses = StratFeeManagerInitializable.CommonAddresses(
            address(vault2),
            unirouter,
            strategist,
            address(factory)
        );

        strategy2.initialize(
            pool, 
            quoter,
            width,
            path0,
            path1,
            commonAddresses
        );

        address _want = vault.want();
        assertEq(_want, pool);

        address[] memory lpToken0Route = strategy.lpToken0ToNative();
        address[] memory lpToken1Route = strategy.lpToken1ToNative();
        assertEq(lpToken0Route.length, 0);
        assertEq(lpToken1Route.length, 2);

    }
/*
    function test_scenario_one() public {
        console.log("");
        console.log("Scenario 2");
        console.log("");
        address user2 = vm.addr(1);
        address trader = vm.addr(2);

        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        // Test preview and use this as min expected output on deposit. 
        uint _shares = vault.previewDeposit(token0Size, token1Size);
        vault.depositAll(_shares);

        uint256 shares0 = vault.balanceOf(user);
        console.log("User 1 Shares:", shares0);

        (uint256 balBefuser0, uint256 balBefuser1) = vault.previewWithdraw(shares0);
        console.log("User 1 Deposit Balance 0:", balBefuser0);
        console.log("User 1 Deposit Balance 1:", balBefuser1);
        console.log("");
        vm.stopPrank();

        vm.startPrank(user2); 
        deal(address(token0), user2, token0Size * 2);

        IERC20(token0).forceApprove(address(vault2), token0Size * 2);

        // Test preview and use this as min expected output on deposit. 
        _shares = vault2.previewDeposit(token0Size, 0);
        vault2.depositAll(_shares);

        uint shares1 = vault2.balanceOf(user2);
        console.log("User 2 Shares:", shares1);
        (uint256 balBefuser20, uint256 balBefuser21) = vault2.previewWithdraw(shares1);

        console.log("User 2 Deposit Balance 0:", balBefuser20);
        console.log("User 2 Deposit Balance 1:", balBefuser21);

        console.log("");
        (balBefuser0, balBefuser1) = vault.previewWithdraw(shares0);
        console.log("User 1 Deposit Balance after User 2 Deposit 0:", balBefuser0);
        console.log("User 1 Deposit Balance after User 2 Deposit 1:", balBefuser1);
        console.log("");
        vm.stopPrank();

        vm.startPrank(trader);
        deal(address(token0), trader, token0Size);
        deal(address(token1), trader, token1Size);

        IERC20(token0).forceApprove(address(unirouter), type(uint256).max);
        IERC20(token1).forceApprove(address(unirouter), type(uint256).max);

       // console.log("Trader Bal0:", token0Size);

        for (uint i; i < 5; ++i) {
                UniV3Utils.swap(trader, unirouter, tradePath, token0Size / 10);
                UniV3Utils.swap(trader, unirouter, path1, token1Size / 5);
        }

        strategy.harvest();

        vm.stopPrank();

        vm.startPrank(user);

        skip(1  days);
        
        shares0 = vault.balanceOf(user);
        shares1 = vault2.balanceOf(user2);

        (uint256 balUser0, uint256 balUser1) = vault.previewWithdraw(shares0);
        (uint256 balUser20, uint256 balUser21) = vault2.previewWithdraw(shares1);

        console.log("");
        console.log("After Several Trades");
        console.log("");
        console.log("User Bal0:", balUser0);    
        console.log("User Bal1:", balUser1);
        console.log("");
        console.log("User2 Bal0:", balUser20);
        console.log("User2 Bal1:", balUser21);

        vm.stopPrank();
    }

    function test_scenario_two() public {
        address user2 = vm.addr(1);
        address trader = vm.addr(2);

        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        // Test preview and use this as min expected output on deposit. 
        uint _shares = vault.previewDeposit(token0Size, token1Size);
        vault.depositAll(_shares);

        uint256 shares0 = vault.balanceOf(user);
        console.log("User 1 Shares:", shares0);

        (uint256 balBefuser0, uint256 balBefuser1) = vault.previewWithdraw(shares0);
        console.log("User 1 Deposit Balance 0:", balBefuser0);
        console.log("User 1 Deposit Balance 1:", balBefuser1);
        console.log("");
        vm.stopPrank();

        vm.startPrank(user2); 
        deal(address(token0), user2, token0Size * 2);

        IERC20(token0).forceApprove(address(vault), token0Size * 2);

        // Test preview and use this as min expected output on deposit. 
        _shares = vault.previewDeposit(token0Size, 0);
        vault.depositAll(_shares);

        uint shares1 = vault.balanceOf(user2);
        console.log("User 2 Shares:", shares1);
        (uint256 balBefuser20, uint256 balBefuser21) = vault.previewWithdraw(shares1);

        console.log("User 2 Deposit Balance 0:", balBefuser20);
        console.log("User 2 Deposit Balance 1:", balBefuser21);

        console.log("");
        (balBefuser0, balBefuser1) = vault.previewWithdraw(shares0);
        console.log("User 1 Deposit Balance after User 2 Deposit 0:", balBefuser0);
        console.log("User 1 Deposit Balance after User 2 Deposit 1:", balBefuser1);
        console.log("");
        vm.stopPrank();

        vm.startPrank(trader);
        deal(address(token0), trader, token0Size);
        deal(address(token1), trader, token1Size);

        IERC20(token0).forceApprove(address(unirouter), type(uint256).max);
        IERC20(token1).forceApprove(address(unirouter), type(uint256).max);

       // console.log("Trader Bal0:", token0Size);

        for (uint i; i < 5; ++i) {
                UniV3Utils.swap(trader, unirouter, tradePath, token0Size / 10);
                UniV3Utils.swap(trader, unirouter, path1, token1Size / 5);
        }

        strategy.harvest();

        vm.stopPrank();

        vm.startPrank(user);

        skip(1  days);
        
        shares0 = vault.balanceOf(user);
        shares1 = vault.balanceOf(user2);

        (uint256 balUser0, uint256 balUser1) = vault.previewWithdraw(shares0);
        (uint256 balUser20, uint256 balUser21) = vault.previewWithdraw(shares1);

        console.log("");
        console.log("After Several Trades");
        console.log("");
        console.log("User Bal0:", balUser0);    
        console.log("User Bal1:", balUser1);
        console.log("");
        console.log("User2 Bal0:", balUser20);
        console.log("User2 Bal1:", balUser21);

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