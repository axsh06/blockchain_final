// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Создаем мок-токен для тестирования
contract MockToken is ERC20 {
    constructor() ERC20("Mock Asset", "MASK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract YieldVaultTest is Test {
    YieldVault public vault;
    MockToken public asset;
    address public user = address(1);

    function setUp() public {
        asset = new MockToken();
        vault = new YieldVault(asset);

        // Даем юзеру баланс для тестов
        asset.mint(user, 100000e18);
    }

    function test_DepositAndWithdraw() public {
        vm.startPrank(user);
        asset.approve(address(vault), 1000e18);

        // Юзер депозитит 1000 токенов
        uint256 shares = vault.deposit(1000e18, user);
        assertEq(shares, 1000e18); // Должен получить 1000 shares
        assertEq(vault.balanceOf(user), 1000e18);

        // Юзер выводит 500 токенов
        uint256 assets = vault.withdraw(500e18, user, user);
        assertEq(assets, 500e18);
        vm.stopPrank();
    }

    // Fuzz-тест: Проверка ERC-4626 Rounding Invariants (юзер не должен получить выгоду из-за округления)
    function testFuzz_VaultRoundingInvariant(uint256 amountIn) public {
        amountIn = bound(amountIn, 1, 10000e18); // От 1 wei до 10k токенов

        vm.startPrank(user);
        asset.approve(address(vault), amountIn);

        uint256 shares = vault.deposit(amountIn, user);
        uint256 withdrawnAssets = vault.redeem(shares, user, user);

        // Главное правило: выведенные активы <= изначально задепозиченным
        assertTrue(withdrawnAssets <= amountIn, "Rounding invariant broken");
        vm.stopPrank();
    }
}
