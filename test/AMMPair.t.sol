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

    address public user = address(1);

    function setUp() public {
        token0 = new MockToken("Token0", "TK0");
        token1 = new MockToken("Token1", "TK1");
        pair = new AMMPair(address(token0), address(token1));

        // Даем юзеру токены
        token0.mint(user, 1000000e18);
        token1.mint(user, 1000000e18);

        vm.startPrank(user);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);

        // Начальная ликвидность
        pair.addLiquidity(100000e18, 100000e18);
        vm.stopPrank();
    }

    // Fuzz-тест для функции swap (случайные суммы)
    function testFuzz_Swap(uint256 amountIn) public {
        // Ограничиваем ввод от 1 целого токена до 10 000 токенов
        amountIn = bound(amountIn, 1e18, 10000e18);

        vm.startPrank(user);
        uint256 balanceBefore = token1.balanceOf(user);

        pair.swap(address(token0), amountIn, 0);

        uint256 balanceAfter = token1.balanceOf(user);
        assertTrue(balanceAfter > balanceBefore, "Swap failed");
        vm.stopPrank();
    }

    // Invariant-тест: проверяем, что x * y = k не уменьшается
    function testFuzz_Invariant_K_DoesNotDecrease(uint256 amountIn) public {
        // Ограничиваем ввод от 1 целого токена до 10 000 токенов
        amountIn = bound(amountIn, 1e18, 10000e18);

        uint256 kBefore = pair.reserve0() * pair.reserve1();

        vm.startPrank(user);
        pair.swap(address(token0), amountIn, 0);
        vm.stopPrank();

        uint256 kAfter = pair.reserve0() * pair.reserve1();
        assertTrue(kAfter >= kBefore, "Invariant broken: K decreased");
    }
}
