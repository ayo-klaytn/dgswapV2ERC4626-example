// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { DgswapV2ERC4626 } from "../src/erc4626/DgswapV2ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol"; 
import {IUniswapV2Pair} from "../src/erc4626/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "../src/erc4626/interfaces/IUniswapV2Router.sol";

contract UniswapV2ERC4626Script is Script {

    DgswapV2ERC4626 public dgswapV2ERC4626;
    string name_ = "vUSDT";
    string symbol_ = "vUSDT";

    ERC20 asset_ = ERC20(0x4E6DE3b8D9C3a773df245590E80e229B0deafFa0);
    IERC20 token0_ = IERC20(0xd077A400968890Eacc75cdc901F0356c943e4fDb);
    IERC20 token1_ = IERC20(0x02cbE46fB8A1F579254a9B485788f2D86Cad51aa);
    IUniswapV2Router router_ = IUniswapV2Router(0x8203cBc504CE43c3Cad07Be0e057f25B1d4DB578);
    IUniswapV2Pair pair_ = IUniswapV2Pair(0x4E6DE3b8D9C3a773df245590E80e229B0deafFa0);

    uint slippage_ = 9500;


    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dgswapV2ERC4626 = new DgswapV2ERC4626(name_, symbol_, asset_, token0_, token1_, router_, pair_, slippage_);

        vm.stopBroadcast();
    }
}
