// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {DgswapV2ERC4626} from "../src/erc4626/DgswapV2ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Pair} from "../src/erc4626/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "../src/erc4626/interfaces/IUniswapV2Router.sol";
import {
    IUniswapV2Factory
} from "../src/erc4626/interfaces/IUniswapV2Factory.sol";

contract UniswapV2ERC4626Test is Test {
    // Kaia mainnet addresses
    IERC20 usdt = IERC20(0xd077A400968890Eacc75cdc901F0356c943e4fDb);
    IERC20 elde = IERC20(0x8755D2e532b1559454689Bf0E8964Bd78b187Ff6);
    IUniswapV2Router router =
        IUniswapV2Router(0x8203cBc504CE43c3Cad07Be0e057f25B1d4DB578);

    IUniswapV2Factory factory;
    IUniswapV2Pair pair;
    DgswapV2ERC4626 vault;

    // Test actors
    address liquidityProvider = makeAddr("liquidityProvider");
    address vaultUser = makeAddr("vaultUser");
    address trader = makeAddr("trader");

    function setUp() public {
        console2.log("\n====================================");
        console2.log("  Mock USDT/ELDE Vault Setup");
        console2.log("====================================\n");

        // Get factory
        factory = IUniswapV2Factory(0x224302153096E3ba16c4423d9Ba102D365a94B2B);
        console2.log("Router:", address(router));
        console2.log("Factory:", address(factory));
        console2.log("USDT:", address(usdt));
        console2.log("ELDE:", address(elde));

        // Step 1: Create pair (or get existing)
        console2.log("\n[1/4] Creating/Getting pair...");
        address pairAddress = factory.getPair(address(usdt), address(elde));

        if (pairAddress == address(0)) {
            // Create new pair
            vm.prank(liquidityProvider);
            pairAddress = factory.createPair(address(usdt), address(elde));
            console2.log("  New pair created:", pairAddress);
        } else {
            console2.log("  Pair exists:", pairAddress);
        }

        pair = IUniswapV2Pair(pairAddress);

        // Step 2: Add initial liquidity
        console2.log("\n[2/4] Adding initial liquidity...");
        _addInitialLiquidity();

        // Step 3: Deploy vault
        console2.log("\n[3/4] Deploying vault...");
        vault = new DgswapV2ERC4626(
            "vUSDTe",
            "vUSDTe",
            ERC20(address(pair)),
            usdt,
            elde,
            router,
            pair,
            9500 // 95% slippage
        );
        console2.log("  Vault deployed:", address(vault));

        // Step 4: Verify setup
        console2.log("\n[4/4] Verifying setup...");
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console2.log("  Pool reserves:");
        console2.log("    Reserve0:", reserve0);
        console2.log("    Reserve1:", reserve1);

        uint256 lpSupply = pair.totalSupply();
        console2.log("  LP total supply:", lpSupply);

        console2.log("\nSetup complete!\n");
    }

    function _addInitialLiquidity() internal {
        // Give liquidity provider tokens using deal
        uint256 usdtAmount = 10_000 * 1e6; // 10k USDT
        uint256 eldeAmount = 4_000_000 * 1e18; // 4M ELDE (400:1 ratio)

        deal(address(usdt), liquidityProvider, usdtAmount);
        deal(address(elde), liquidityProvider, eldeAmount);

        console2.log("  LP Provider balance:");
        console2.log("    USDT:");
        console2.log(usdtAmount / 1e6);
        console2.log("    ELDE:");
        console2.log(eldeAmount / 1e18);

        // Add liquidity
        vm.startPrank(liquidityProvider);

        usdt.approve(address(router), usdtAmount);
        elde.approve(address(router), eldeAmount);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                address(usdt),
                address(elde),
                usdtAmount,
                eldeAmount,
                0,
                0,
                liquidityProvider,
                block.timestamp + 100
            );

        vm.stopPrank();

        console2.log("  Liquidity added:");
        console2.log("    USDT:");
        console2.log(amountA / 1e6);
        console2.log("    ELDE:");
        console2.log(amountB / 1e18);
        console2.log("    LP tokens:");
        console2.log(liquidity);
    }

    function test_DepositAndEarnFees() public {
        console2.log("=== Deposit - Swap - Earn ===\n");

        // Step 1: Give vault user tokens
        console2.log("Step 1: Giving vault user tokens...");
        _giveTokens();

        // Step 2: User deposits
        console2.log("\nStep 2: Vault user deposits...");
        uint256 depositAmount = 1_000_000_000_000_000_000; // 1.0 LP
        uint256 shares = _userDeposit(depositAmount);

        // Step 3: Record BEFORE
        console2.log("\nStep 3: Recording BEFORE state...");
        (uint256 usdtBefore, uint256 eldeBefore) = vault.getAssetsAmounts(
            depositAmount
        );
        console2.log("LP Value BEFORE:");
        console2.log("  USDT wei:", usdtBefore);
        console2.log("  USDT:", usdtBefore / 1e6);
        console2.log("  ELDE wei:", eldeBefore);
        console2.log("  ELDE:", eldeBefore / 1e18);

        uint256 valueBefore = _calculateValue(usdtBefore, eldeBefore);
        console2.log("  Total USD:", valueBefore / 1e6);

        // Step 4: Trader swaps
        console2.log("\nStep 4: Trader generating fees...");
        _traderSwaps(100);

        // Step 5: Record AFTER
        console2.log("\nStep 5: Recording AFTER state...");
        (uint256 usdtAfter, uint256 eldeAfter) = vault.getAssetsAmounts(
            depositAmount
        );
        console2.log("LP Value AFTER:");
        console2.log("  USDT wei:", usdtAfter);
        console2.log("  USDT:", usdtAfter / 1e6);
        console2.log("  ELDE wei:", eldeAfter);
        console2.log("  ELDE:", eldeAfter / 1e18);

        uint256 valueAfter = _calculateValue(usdtAfter, eldeAfter);
        console2.log("  Total USD:", valueAfter / 1e6);

        // Step 6: Calculate profit
        console2.log("\n=== PROFIT ===");
        int256 usdtChange = int256(usdtAfter) - int256(usdtBefore);
        int256 eldeChange = int256(eldeAfter) - int256(eldeBefore);
        int256 valueChange = int256(valueAfter) - int256(valueBefore);

        console2.log("USDT change:");
        if (usdtChange >= 0) {
            console2.log("  Plus wei:", uint256(usdtChange));
            console2.log("  Plus USDT:", uint256(usdtChange) / 1e6);
        } else {
            console2.log("  Minus wei:", uint256(-usdtChange));
            console2.log("  Minus USDT:", uint256(-usdtChange) / 1e6);
        }

        console2.log("ELDE change:");
        if (eldeChange >= 0) {
            console2.log("  Plus wei:", uint256(eldeChange));
            console2.log("  Plus ELDE:", uint256(eldeChange) / 1e18);
        } else {
            console2.log("  Minus wei:", uint256(-eldeChange));
            console2.log("  Minus ELDE:", uint256(-eldeChange) / 1e18);
        }

        console2.log("Total value change:");
        if (valueChange >= 0) {
            console2.log("  Plus USD:", uint256(valueChange) / 1e6);
        } else {
            console2.log("  Minus USD:", uint256(-valueChange) / 1e6);
        }

        if (usdtChange > 0 && eldeChange > 0) {
            console2.log("\nYou earned fees on both assets with minimal IL!");
        } else if (valueChange > 0) {
            console2.log("\nNet positive despite some rebalancing!");
        } else if (usdtChange > 0) {
            console2.log("\nYou earned fees!");
        } else {
            console2.log("\nImpermanent loss exceeded fees earned");
        }

        assertGt(shares, 0, "Should have shares");
    }

    function test_RedeemAfterFees() public {
        console2.log("=== Full Cycle ===\n");

        _giveTokens();

        // Record initial
        uint256 usdtInitial = usdt.balanceOf(vaultUser);
        uint256 eldeInitial = elde.balanceOf(vaultUser);
        console2.log("Initial balances:");
        console2.log("  USDT:", usdtInitial / 1e6);
        console2.log("  ELDE:", eldeInitial / 1e18);

        // Deposit
        uint256 depositAmount = 1_000_000_000_000_000_000;
        uint256 shares = _userDeposit(depositAmount);

        console2.log("\nAfter deposit:");
        console2.log("  Shares:", shares);

        // Generate fees
        console2.log("\nGenerating fees...");
        _traderSwaps(100);

        // Redeem
        console2.log("\nRedeeming...");
        vm.startPrank(vaultUser);
        vault.redeem(shares, vaultUser, vaultUser);
        vm.stopPrank();

        // Final balances
        uint256 usdtFinal = usdt.balanceOf(vaultUser);
        uint256 eldeFinal = elde.balanceOf(vaultUser);
        console2.log("\nFinal balances:");
        console2.log("  USDT:", usdtFinal / 1e6);
        console2.log("  ELDE:", eldeFinal / 1e18);

        console2.log("\nNet profit:");
        int256 netUsdt = int256(usdtFinal) - int256(usdtInitial);
        int256 netElde = int256(eldeFinal) - int256(eldeInitial);

        if (netUsdt >= 0) {
            console2.log("  USDT plus:", uint256(netUsdt) / 1e6);
        } else {
            console2.log("  USDT minus:", uint256(-netUsdt) / 1e6);
        }

        if (netElde >= 0) {
            console2.log("  ELDE plus:", uint256(netElde) / 1e18);
        } else {
            console2.log("  ELDE minus:", uint256(-netElde) / 1e18);
        }

        console2.log("\nComplete!");
    }

    function _giveTokens() internal {
        deal(address(usdt), vaultUser, 500_000 * 1e6);
        deal(address(elde), vaultUser, 200_000_000 * 1e18);

        deal(address(usdt), trader, 500_000 * 1e6);
        deal(address(elde), trader, 200_000_000 * 1e18);

        console2.log("  Tokens given to users");
    }

    function _userDeposit(uint256 lpAmount) internal returns (uint256 shares) {
        (uint256 usdtNeeded, uint256 eldeNeeded) = vault.getAssetsAmounts(
            lpAmount
        );

        console2.log("  Required:");
        console2.log("    USDT:", usdtNeeded / 1e6);
        console2.log("    ELDE:", eldeNeeded / 1e18);

        vm.startPrank(vaultUser);

        usdt.approve(address(vault), (usdtNeeded * 120) / 100);
        elde.approve(address(vault), (eldeNeeded * 120) / 100);

        shares = vault.deposit(lpAmount, vaultUser);

        vm.stopPrank();

        console2.log("  Deposited! Shares:", shares);
        return shares;
    }

function _traderSwaps(uint256 numSwaps) internal {
    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
    
    // Determine which token is which
    bool isToken0USDT = pair.token0() == address(usdt);
    
    // Store initial reserves for comparison
    uint256[2] memory initialReserves;
    initialReserves[0] = isToken0USDT ? uint256(reserve0) : uint256(reserve1); // USDT
    initialReserves[1] = isToken0USDT ? uint256(reserve1) : uint256(reserve0); // ELDE
    
    // Calculate swap amounts - 0.1% of pool per swap
    uint256[2] memory swapAmounts;
    swapAmounts[0] = initialReserves[0] / 1000; // USDT amount
    swapAmounts[1] = initialReserves[1] / 1000; // ELDE amount
    
    console2.log("  Pool reserves:");
    console2.log("    USDT:", initialReserves[0] / 1e6);
    console2.log("    ELDE:", initialReserves[1] / 1e18);
    console2.log("  Swap amounts per trade:");
    console2.log("    USDT:", swapAmounts[0] / 1e6);
    console2.log("    ELDE:", swapAmounts[1] / 1e18);
    
    // Execute swaps
    for (uint256 i = 0; i < numSwaps; i++) {
        vm.startPrank(trader);
        
        address[] memory path = new address[](2);
        
        if (i % 2 == 0) {
            // Swap USDT → ELDE
            usdt.approve(address(router), swapAmounts[0]);
            path[0] = address(usdt);
            path[1] = address(elde);
            
            router.swapExactTokensForTokens(
                swapAmounts[0],
                0,
                path,
                trader,
                block.timestamp + 100
            );
        } else {
            // Swap ELDE → USDT
            elde.approve(address(router), swapAmounts[1]);
            path[0] = address(elde);
            path[1] = address(usdt);
            
            router.swapExactTokensForTokens(
                swapAmounts[1],
                0,
                path,
                trader,
                block.timestamp + 100
            );
        }
        
        vm.stopPrank();
        vm.roll(block.number + 1);
    }
    
    // Calculate approximate fees (0.3% of volume)
    uint256[2] memory feesGenerated;
    feesGenerated[0] = (swapAmounts[0] * (numSwaps / 2) * 30) / 10000;
    feesGenerated[1] = (swapAmounts[1] * ((numSwaps + 1) / 2) * 30) / 10000;
    
    console2.log("\n  Trading complete!");
    console2.log("  Swaps executed:");
    console2.log("    USDT->ELDE:", numSwaps / 2);
    console2.log("    ELDE->USDT:", (numSwaps + 1) / 2);
    console2.log("  Estimated fees generated (0.3% per swap):");
    console2.log("    USDT fees:", feesGenerated[0] / 1e6);
    console2.log("    ELDE fees:", feesGenerated[1] / 1e18);
    
    // Get final state
    (reserve0, reserve1,) = pair.getReserves();
    console2.log("  Final pool reserves:");
    console2.log("    USDT:", (isToken0USDT ? uint256(reserve0) : uint256(reserve1)) / 1e6);
    console2.log("    ELDE:", (isToken0USDT ? uint256(reserve1) : uint256(reserve0)) / 1e18);
}
    function _calculateValue(
        uint256 usdtAmount,
        uint256 eldeAmount
    ) internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        // Calculate ELDE price in USDT
        uint256 eldePrice = (uint256(reserve0) * 1e18) / uint256(reserve1);
        uint256 eldeValueInUsdt = (eldeAmount * eldePrice) / 1e18;

        return usdtAmount + eldeValueInUsdt;
    }
}
