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

// Test WBTC/ETH Uniswap Strategy. Small decimal token0 and large decimal token1;
contract ConLiqWBTCETHTest is Test {
    BeefyVaultConcLiq vault;
    BeefyVaultConcLiqFactory vaultFactory;
    StrategyPassiveManagerUniswap strategy;
    StrategyPassiveManagerUniswap implementation;
    StrategyFactory factory;
    address constant pool = 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
    address constant token0 = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant native = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant strategist = 0xb2e4A61D99cA58fB8aaC58Bb2F8A59d63f552fC0;
    address constant beefyFeeRecipient = 0x65f2145693bE3E75B8cfB2E318A3a74D057e6c7B;
    address constant beefyFeeConfig = 0x3d38BA27974410679afF73abD096D7Ba58870EAd;
    address constant unirouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant quoter = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    address constant keeper = 0x4fED5491693007f0CD49f4614FFC38Ab6A04B619;
    int24 constant width = 500;
    address constant user = 0x161D61e30284A33Ab1ed227beDcac6014877B3DE;
    uint token0Size = 1e8;
    uint token1Size = 10 ether;
    bytes tradePath;
    bytes path0;

    function setUp() public {
        BeefyVaultConcLiq vaultImplementation = new BeefyVaultConcLiq();
        vaultFactory = new BeefyVaultConcLiqFactory(address(vaultImplementation));
        vault = vaultFactory.cloneVault();
        implementation = new StrategyPassiveManagerUniswap();
        factory = new StrategyFactory(native, keeper, beefyFeeRecipient, beefyFeeConfig);
        
        address[] memory lpToken0ToNative = new address[](2);
        lpToken0ToNative[0] = token0;
        lpToken0ToNative[1] = native;

        address[] memory lpToken1ToNative = new address[](2);
        lpToken1ToNative[0] = token1;
        lpToken1ToNative[1] = native;

        address[] memory tradeRoute = new address[](2);
        tradeRoute[0] = native;
        tradeRoute[1] = token0;

        uint24[] memory fees = new uint24[](1);
        fees[0] = 500;

        path0 = routeToPath(lpToken0ToNative, fees);
        //bytes memory path1 = routeToPath(lpToken1ToNative, fees);
        bytes memory path1 = "";
        tradePath = routeToPath(tradeRoute, fees);

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

    }
/*
    function test_deposit() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).approve(address(vault), token0Size);
        IERC20(token1).approve(address(vault), token1Size);

        (uint _shares, uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);

        vault.deposit(amount0, amount1, _shares);

        uint256 shares = vault.balanceOf(user);
        console.log(shares);

        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, token0Size, 2);
        assertApproxEqAbs(bal1, token1Size, 2);
        vm.stopPrank();
    }

    function test_twoUserDeposit() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).approve(address(vault), token0Size);
        IERC20(token1).approve(address(vault), token1Size);

        (uint _shares, uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);

        vault.deposit(amount0, amount1, _shares);

        uint256 shares = vault.balanceOf(user);
        console.log(shares);

        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, token0Size, 2);
        assertApproxEqAbs(bal1, token1Size, 2);
        vm.stopPrank();

        vm.startPrank(keeper);
        deal(address(token0), keeper, token0Size);
        deal(address(token1), keeper, token1Size);

        IERC20(token0).approve(address(vault), token0Size);
        IERC20(token1).approve(address(vault), token1Size);

        (_shares, amount0, amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        shares = vault.balanceOf(keeper);
        console.log(shares);

        vm.stopPrank();
    }
*/
    function test_withdraw() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).approve(address(vault), token0Size);
        IERC20(token1).approve(address(vault), token1Size);

        (uint256 _shares, uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, token0Size, 2);
        assertApproxEqAbs(bal1, token1Size, 2);

        uint256 shares = vault.balanceOf(user);
        (uint256 _slip0, uint256 _slip1) = vault.previewWithdraw(shares / 2);
        vault.withdraw(shares / 2, _slip0, _slip1);

        deal(address(token0), user, token0Size);

        IERC20(token0).approve(address(unirouter), token0Size);
        UniV3Utils.swap(unirouter, path0, token0Size / 2);

        uint256 _sharesBal = IERC20(address(vault)).balanceOf(user);
        (_slip0, _slip1) = vault.previewWithdraw(_sharesBal);
        vault.withdrawAll(_slip0, _slip1);

        amount0 = strategy.totalLocked0();
        amount1 = strategy.totalLocked1();
        console.log(amount0, amount1);

        vm.stopPrank();
    }

    function test_harvest() public {
        vm.startPrank(user); 
      
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).approve(address(vault), token0Size);
        IERC20(token1).approve(address(vault), token1Size);

        (uint256 _shares, uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0,  token0Size, 2);
        assertApproxEqAbs(bal1, token1Size, 2);

        deal(address(token0), user, token0Size);

        IERC20(token0).approve(address(unirouter), token0Size);
        UniV3Utils.swap(unirouter, path0, token0Size);

        uint256 nativeBal = IERC20(native).balanceOf(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        deal(address(native), user, nativeBal);

        skip(8 hours);

        strategy.harvest();

        IERC20(native).approve(address(unirouter), nativeBal);
        UniV3Utils.swap(unirouter, tradePath, nativeBal);

        skip(8 hours);

        strategy.harvest();

        skip(1 days);
     
        (, ,uint256 main0,uint256 main1,uint256 alt0,uint256 alt1) = strategy.balancesOfPool();
        console.log(main0);
        console.log(main1);
        console.log(alt0);
        console.log(alt1);

        vm.stopPrank();

        vm.startPrank(keeper);
        deal(address(token0), keeper, token0Size * 2);
        deal(address(token1), keeper, token1Size * 2);

        IERC20(token0).approve(address(vault), token0Size);
        IERC20(token1).approve(address(vault), token1Size);

        (_shares, amount0, amount1) = vault.previewDeposit(token0Size, token1Size); 
        vault.deposit(amount0, amount1, _shares);

        IERC20(token0).approve(address(unirouter), token0Size);
        UniV3Utils.swap(unirouter, path0, token0Size);

        skip(1 hours);

        strategy.harvest();

        vm.stopPrank();
        vm.startPrank(user);

        uint256 _sharesBal = IERC20(address(vault)).balanceOf(user);
        (uint256 _slip0, uint256 _slip1) = vault.previewWithdraw(_sharesBal);
        vault.withdrawAll(_slip0, _slip1);

        vm.stopPrank();
    }

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