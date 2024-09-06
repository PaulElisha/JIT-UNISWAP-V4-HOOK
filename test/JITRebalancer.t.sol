// SPDX-License-Identifier: MITrebalance
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {JITRebalancer} from "../src/JITRebalancer.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

contract JITRebalancerTest is Test {
    JITRebalancer jitRebalancer;
    MockERC20 token0;
    MockERC20 token1;
    address manager = makeAddr("manager");
    address router = makeAddr("router");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        token0 = new MockERC20();
        token1 = new MockERC20();
        jitRebalancer = new JITRebalancer(address(token0), address(token1), router);
    }

    function test_deposit() public {
        vm.startPrank(user1);
        token0.mint(user1, 1 ether);
        token1.mint(address(jitRebalancer), 1 ether);
        token0.approve(address(jitRebalancer), 1 ether);
        jitRebalancer.depositLiquidity(0.5 ether);
        console2.log(jitRebalancer.balanceOf(user1));
        jitRebalancer.depositLiquidity(0.5 ether);
        console2.log(jitRebalancer.balanceOf(user1));
        console2.log("--------------------------------");
        vm.stopPrank();

        vm.startPrank(user2);
        token0.mint(user2, 1 ether);
        token0.approve(address(jitRebalancer), 1 ether);
        jitRebalancer.depositLiquidity(0.5 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        jitRebalancer.withdrawLiquidity(1 ether);
        console2.log(jitRebalancer.balanceOf(user1), token0.balanceOf(user1), token1.balanceOf(user1));
        assertEq(jitRebalancer.balanceOf(user1), 0);
        assertApproxEqAbs(
            token0.balanceOf(user1),
            token0.balanceOf(address(jitRebalancer)) * 1 ether / jitRebalancer.totalSupply(),
            10 wei,
            "not eq token 0"
        );
        // (token0.balanceOf(user1), token0.balanceOf(address(jitRebalancer)) * 1 ether / jitRebalancer.totalSupply());
        assertApproxEqAbs(
            token1.balanceOf(user1),
            token1.balanceOf(address(jitRebalancer)) * 1 ether / jitRebalancer.totalSupply(),
            10 wei,
            "not eq token 1"
        );

        // assertEq(token1.balanceOf(user1), token1.balanceOf(address(jitRebalancer)) * 1 ether / jitRebalancer.totalSupply());
    }
}