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
contract ConLiqSetterTest is Test {
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
    address constant unirouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant quoter = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    address constant keeper = 0x4fED5491693007f0CD49f4614FFC38Ab6A04B619;
    int24 constant width = 500;
    address constant user = 0x161D61e30284A33Ab1ed227beDcac6014877B3DE;
    uint token0Size = 10 ether;
    uint token1Size = 20000e6;
    bytes tradePath;
    bytes path0;
    bytes path1;
    
    error TicksDidNotChange();

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
        tradeRoute[1] = token1;

        uint24[] memory fees = new uint24[](1);
        fees[0] = 3000;

        path0 = ""; //routeToPath(lpToken0ToNative, fees);
        path1 = routeToPath(lpToken1ToNative, fees);
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

    function test_setters() public {
        vm.startPrank(user); 
        deal(address(token0), user, token0Size);
        deal(address(token1), user, token1Size);

        IERC20(token0).forceApprove(address(vault), token0Size);
        IERC20(token1).forceApprove(address(vault), token1Size);

        (uint256 _shares, uint256 amount0, uint256 amount1) = vault.previewDeposit(token0Size, token1Size);

        vault.deposit(amount0, amount1, _shares);

        //uint256 shares = vault.balanceOf(user);
        //console.log(shares);

        (uint256 newAmount0, uint256 newAmount1) = strategy.balances();
        assertApproxEqAbs(amount0, newAmount0, 2);
        assertApproxEqAbs(amount1, newAmount1, 2);
        vm.stopPrank();

        address owner = strategy.owner();
        vm.startPrank(owner);
        
        // Test setting the width of the strategy. 
        (amount0, amount1) = vault.balances();
        (int24 mainLower, int24 mainUpper) = strategy.positionMain();
        (int24 altLower, int24 altUpper) = strategy.positionAlt();
        strategy.setPositionWidth(1000);
        (newAmount0, newAmount1) = strategy.balances();
        assertApproxEqAbs(amount0, newAmount0, 2);
        assertApproxEqAbs(amount1, newAmount1, 2);

        (int24 newMainLower, int24 newMainUpper) = strategy.positionMain();
        (int24 newAltLower, int24 newAltUpper) = strategy.positionAlt();
        if (
            mainLower == newMainLower ||
            mainUpper == newMainUpper 
        ) revert TicksDidNotChange();

        if (
            altLower == newAltLower &&
            altUpper == newAltUpper 
        ) revert TicksDidNotChange();

        // Test panic and unpause. 
        (amount0, amount1) = strategy.balances();
        strategy.panic(amount0, amount1);

        // Everything should be in the strategy
        (newAmount0, newAmount1) = strategy.balancesOfThis();
        assertApproxEqAbs(amount0, newAmount0, 2);
        assertApproxEqAbs(amount1, newAmount1, 2);

        strategy.unpause();

        (newAmount0, newAmount1) = strategy.balances();
        assertApproxEqAbs(amount0, newAmount0, 2);
        assertApproxEqAbs(amount1, newAmount1, 2);

        // Check setting deviation 
        strategy.setDeviation(200);
        assertEq(strategy.maxTickDeviation(), 200);

        // Check setting twap interval
        strategy.setTwapInterval(60);
        assertEq(strategy.twapInterval(), 60);
       
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