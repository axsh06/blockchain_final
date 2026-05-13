// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {GovToken} from "../src/GovToken.sol";

contract YieldVaultExtendedTest is Test {
    YieldVault vault;
    GovToken token;
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new GovToken();
        vault = new YieldVault(token);
        
        token.mint(user1, 10000e18);
        token.mint(user2, 10000e18);

        vm.startPrank(user1);
        token.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    // --- View функции ERC4626 ---
    function test_Asset() public view { assertEq(vault.asset(), address(token)); }
    function test_TotalAssetsZero() public view { assertEq(vault.totalAssets(), 0); }
    function test_ConvertToShares1to1() public view { assertEq(vault.convertToShares(100e18), 100e18); }
    function test_ConvertToAssets1to1() public view { assertEq(vault.convertToAssets(100e18), 100e18); }
    function test_MaxDeposit() public view { assertTrue(vault.maxDeposit(user1) > 0); }
    function test_MaxMint() public view { assertTrue(vault.maxMint(user1) > 0); }

    // --- Проверки Deposit ---
    function test_Deposit() public {
        vm.startPrank(user1);
        uint256 shares = vault.deposit(1000e18, user1);
        vm.stopPrank();
        assertEq(shares, 1000e18);
        assertEq(vault.balanceOf(user1), 1000e18);
        assertEq(token.balanceOf(address(vault)), 1000e18);
    }

    function test_DepositForOther() public {
        vm.startPrank(user1);
        vault.deposit(1000e18, user2); // Делаем депозит на чужой кошелек
        vm.stopPrank();
        assertEq(vault.balanceOf(user2), 1000e18);
    }

    function test_DepositZeroReturnsZero() public {
        vm.startPrank(user1);
        uint256 shares = vault.deposit(0, user1);
        vm.stopPrank();
        assertEq(shares, 0); // Проверяем, что выдано 0 shares
    }

    // --- Проверки Mint ---
    function test_Mint() public {
        vm.startPrank(user1);
        uint256 assets = vault.mint(500e18, user1);
        vm.stopPrank();
        assertEq(assets, 500e18);
        assertEq(vault.balanceOf(user1), 500e18);
    }

    function test_MintZeroReturnsZero() public {
        vm.startPrank(user1);
        uint256 assets = vault.mint(0, user1);
        vm.stopPrank();
        assertEq(assets, 0); // Проверяем, что забрано 0 assets
    }

    // --- Проверки Withdraw ---
    function test_Withdraw() public {
        vm.startPrank(user1);
        vault.deposit(1000e18, user1);
        uint256 shares = vault.withdraw(500e18, user1, user1);
        vm.stopPrank();
        assertEq(shares, 500e18);
        assertEq(vault.balanceOf(user1), 500e18);
    }

    function test_RevertWithdrawMoreThanBalance() public {
        vm.startPrank(user1);
        vault.deposit(1000e18, user1);
        vm.expectRevert();
        vault.withdraw(2000e18, user1, user1);
        vm.stopPrank();
    }

    // --- Проверки Redeem ---
    function test_Redeem() public {
        vm.startPrank(user1);
        vault.deposit(1000e18, user1);
        uint256 assets = vault.redeem(1000e18, user1, user1);
        vm.stopPrank();
        assertEq(assets, 1000e18);
        assertEq(vault.balanceOf(user1), 0);
    }

    function test_RevertRedeemMoreThanBalance() public {
        vm.startPrank(user1);
        vault.deposit(1000e18, user1);
        vm.expectRevert();
        vault.redeem(2000e18, user1, user1);
        vm.stopPrank();
    }
}