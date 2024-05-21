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

// Test ETH/USDT Uniswap Strategy. Large decimal token0 and small decimal token1;
contract ConLiqETHUSDTTest is Test {
    using SafeERC20 for IERC20;

    BeefyVaultConcLiq vault;
    BeefyVaultConcLiqFactory vaultFactory;
    StrategyPassiveManagerUniswap strategy;
    StrategyPassiveManagerUniswap implementation;
    StrategyFactory factory;
    address constant pool = 0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36;
    address constant token0 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant token1 = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant native = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant strategist = 0xb2e4A61D99cA58fB8aaC58Bb2F8A59d63f552fC0;
    address constant beefyFeeRecipient = 0x65f2145693bE3E75B8cfB2E318A3a74D057e6c7B;
    address constant beefyFeeConfig = 0x3d38BA27974410679afF73abD096D7Ba58870EAd;
    address constant unirouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant keeper = 0x4fED5491693007f0CD49f4614FFC38Ab6A04B619;
    address constant quoter = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    int24 constant width = 500;
    address constant user = 0x161D61e30284A33Ab1ed227beDcac6014877B3DE;
    uint token0Size = 10 ether;
    uint token1Size = 20000e6;
    bytes tradePath;
    bytes path0;
    bytes path1;

    error NotManager();
    error NotCalm();
    error NotVault();
    error StrategyPaused();
    error NoShares();

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
        fees[0] = 3000;

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

    function test_deposit() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        // Test preview and use this as min expected output on deposit. 
        (uint _shares,uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        uint256 shares = vault.balanceOf(user);
        console.log("User Shares :", shares);

        // assert the balances of the vault is equal to the deposit amount 
        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, amount0, 2);
        assertApproxEqAbs(bal1, amount1, 2);

        uint256 lp0Price = strategy.lpToken0ToNativePrice();
        uint256 lp1Price = strategy.lpToken1ToNativePrice();

        console.log("LP0 Price: ", lp0Price);
        console.log("LP1 Price: ", lp1Price);
      //  vm.stopPrank();
    }

    function test_twoUserDeposit() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        (uint _shares,uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        uint256 shares = vault.balanceOf(user);
        console.log("User A :", shares);

        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, amount0, 2);
        assertApproxEqAbs(bal1, amount1, 2);
        vm.stopPrank();

        vm.startPrank(keeper);
        deal(address(token0), keeper, token0Size);
        deal(address(token1), keeper, token1Size / 10);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size / 10);

        (_shares,,) = vault.previewDeposit(token0Size,  0);
        console.log("Shares:", _shares);
        if (_shares != 0) revert ("Shares");

        (_shares,,) = vault.previewDeposit(token0Size, token1Size / 10);
        vault.deposit(token0Size, token1Size / 10, _shares);

        shares = vault.balanceOf(keeper);
        console.log("User B:", shares);

        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        (uint256 _shares, uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        (uint256 bal0, uint256 bal1) = vault.balances();
        assertApproxEqAbs(bal0, amount0, 2);
        assertApproxEqAbs(bal1, amount1, 2);

        uint256 shares = vault.balanceOf(user);
        (uint256 _slip0, uint256 _slip1) = vault.previewWithdraw(shares / 2);
        vault.withdraw(shares / 2, _slip0, _slip1);

        deal(address(token1), user, token1Size);

        IERC20(token1).forceApprove(address(unirouter), token1Size);
        UniV3Utils.swap(unirouter, path1, token1Size / 2);

        uint256 _sharesBal = IERC20(address(vault)).balanceOf(user);
        (_slip0, _slip1) = vault.previewWithdraw(_sharesBal);
        vault.withdrawAll(_slip0, _slip1);

        vm.stopPrank();
    }

    function test_harvest() public {
        vm.startPrank(user); 
      
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        (uint256 _shares,uint256 amount0,uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        deal(address(token1), user, token1Size);

        IERC20(token1).forceApprove(address(unirouter), token1Size);
        UniV3Utils.swap(unirouter, path1, token1Size);

        uint256 nativeBal = IERC20(native).balanceOf(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        deal(address(native), user, nativeBal);

        skip(8 hours);

        strategy.harvest();

        IERC20(native).forceApprove(address(unirouter), nativeBal);
        UniV3Utils.swap(unirouter, tradePath, nativeBal);

        skip(8 hours);

        strategy.harvest();

        skip(1 days);
     
       // (, ,uint256 main0,uint256 main1,uint256 alt0,uint256 alt1) = strategy.balancesOfPool();

        vm.stopPrank();

        vm.startPrank(keeper);
        deal(address(token1), keeper, token1Size * 2);
        deal(address(token0), keeper, token0Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        (_shares,,) = vault.previewDeposit(token0Size, token1Size); 
        vault.deposit(token0Size, token1Size, _shares);

        IERC20(token1).forceApprove(address(unirouter), token1Size);
       
        UniV3Utils.swap(unirouter, path1, token1Size);

        skip(1 hours);

        strategy.harvest(keeper);

        vm.stopPrank();
        vm.startPrank(user);

        uint256 _sharesBal = IERC20(address(vault)).balanceOf(user);
        (uint256 _slip0, uint256 _slip1) = vault.previewWithdraw(_sharesBal);
        vault.withdrawAll(_slip0, _slip1);

        vm.stopPrank();
    }

    function test_malicious_behavior() public {
        vm.startPrank(user); 
      
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), type(uint256).max);
        IERC20(token1).forceApprove(address(vault), type(uint256).max);

        (uint256 _shares,uint256 amount0,uint256 amount1) = vault.previewDeposit(token0Size, token1Size);
        vault.deposit(amount0, amount1, _shares);

        // Test panic on malicious behavior
        vm.expectRevert(NotManager.selector); 
        strategy.panic(0,0);

        vm.stopPrank();
        vm.startPrank(keeper);

        strategy.panic(0,0);

        vm.stopPrank();
        vm.startPrank(user);

        vault.withdrawAll(0,0);

        vm.expectRevert(StrategyPaused.selector);
        vault.deposit(10, 10, 0);

        vm.stopPrank();
        vm.startPrank(keeper);

        strategy.unpause();

        vm.stopPrank();
        vm.startPrank(user);
        
        vault.deposit(IERC20(token0).balanceOf(user), IERC20(token1).balanceOf(user), 0);

        vault.withdrawAll(0,0);

        vm.stopPrank();
        vm.startPrank(keeper);

        factory.pauseAllStrats();

        vm.stopPrank();
        vm.startPrank(user);

        vm.expectRevert(StrategyPaused.selector);
        vault.deposit(10, 10, 0);

        vm.stopPrank();
        address factoryOwner = factory.owner();
        vm.startPrank(factoryOwner);

        factory.unpauseAllStrats();

        vm.stopPrank();
        vm.startPrank(user);

        vault.deposit(IERC20(token0).balanceOf(user), IERC20(token1).balanceOf(user), 0);

        vm.expectRevert("Ownable: caller is not the owner"); 
        strategy.setPositionWidth(1000);

        vm.expectRevert(NotVault.selector);
        strategy.deposit();

        deal(address(token1), user, token1Size * 2001);
        IERC20(token1).forceApprove(address(unirouter), token1Size * 2000);
        UniV3Utils.swap(unirouter, path1, token1Size * 2000);

        IERC20(token1).forceApprove(address(vault), token1Size);
        vm.expectRevert(NotCalm.selector);
        vault.deposit(0, token1Size, 0);

        //vm.expectRevert(NotCalm.selector);
        vault.withdrawAll(0,0);

        address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        deal(address(wbtc), address(vault), 1e8);
        vm.expectRevert("Ownable: caller is not the owner");
        vault.inCaseTokensGetStuck(wbtc);
        
        address owner = vault.owner();
        vm.stopPrank();

        vm.startPrank(owner);
        vault.inCaseTokensGetStuck(wbtc);

        uint256 ownerBal = IERC20(wbtc).balanceOf(owner);
        assertEq(ownerBal, 1e8);
        vm.stopPrank();

        vm.startPrank(factory.owner());
        StrategyPassiveManagerUniswap newImpl = new StrategyPassiveManagerUniswap();
        factory.upgradeTo("StrategyPassiveManagerUniswap_v1", address(newImpl));
        address impl = factory.getImplementation("StrategyPassiveManagerUniswap_v1");
        assertEq(impl, address(newImpl));
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