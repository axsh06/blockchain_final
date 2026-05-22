// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Создаем тестовый токен
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract AMMPairTest is Test {
    AMMPair public pair;
    MockToken public token0;
    MockToken public token1;
    MockToken public invalidToken;

    address public user = address(1);

    function setUp() public {
        token0 = new MockToken("Token0", "TK0");
        token1 = new MockToken("Token1", "TK1");
        invalidToken = new MockToken("Invalid", "INV");

        pair = new AMMPair(address(token0), address(token1));

        // Даем юзеру токены
        token0.mint(user, 1000000e18);
        token1.mint(user, 1000000e18);
        invalidToken.mint(user, 1000000e18);

        vm.startPrank(user);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);

        // Начальная ликвидность
        pair.addLiquidity(100000e18, 100000e18);
        vm.stopPrank();
    }

    // --- СТАРЫЕ ТЕСТЫ (Fuzz и Invariant) ---

    function testFuzz_Swap(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e18, 10000e18);
        vm.startPrank(user);
        uint256 balanceBefore = token1.balanceOf(user);
        pair.swap(address(token0), amountIn, 0);
        assertTrue(token1.balanceOf(user) > balanceBefore, "Swap failed");
        vm.stopPrank();
    }

    function testFuzz_Invariant_K_DoesNotDecrease(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e18, 10000e18);
        uint256 kBefore = pair.reserve0() * pair.reserve1();
        vm.startPrank(user);
        pair.swap(address(token0), amountIn, 0);
        vm.stopPrank();
        assertTrue(pair.reserve0() * pair.reserve1() >= kBefore, "Invariant broken: K decreased");
    }

    // --- НОВЫЕ UNIT-ТЕСТЫ НА ОШИБКИ (Reverts) ---

    function test_RevertIfSwapZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert("Zero amount");
        pair.swap(address(token0), 0, 0); // Пытаемся обменять 0
        vm.stopPrank();
    }

    function test_RevertIfSwapInvalidToken() public {
        vm.startPrank(user);
        vm.expectRevert("Invalid token");
        pair.swap(address(invalidToken), 100e18, 0); // Пытаемся обменять левый токен
        vm.stopPrank();
    }

    function test_RevertIfSlippageTriggered() public {
        vm.startPrank(user);
        vm.expectRevert("Slippage protection triggered");
        // Требуем нереально большую сумму на выход (minAmountOut = 1 000 000)
        pair.swap(address(token0), 100e18, 1000000e18);
        vm.stopPrank();
    }

    function test_AddLiquidityRevertIfZero() public {
        vm.startPrank(user);
        vm.expectRevert("Insufficient liquidity minted");
        pair.addLiquidity(0, 0); // Добавляем 0 ликвидности
        vm.stopPrank();
    }

    function test_RemoveLiquidityRevertIfZero() public {
        vm.startPrank(user);
        vm.expectRevert("Insufficient liquidity burned");
        pair.removeLiquidity(0); // Сжигаем 0 LP токенов
        vm.stopPrank();
    }
}
