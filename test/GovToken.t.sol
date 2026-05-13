// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";

contract GovTokenTest is Test {
    GovToken token;
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new GovToken();
        token.mint(user1, 1000e18);
    }

    // --- Базовые проверки ERC20 ---
    function test_Name() public view { assertEq(token.name(), "DeFi Super Token"); }
    function test_Symbol() public view { assertEq(token.symbol(), "DST"); }
    function test_TotalSupply() public view { assertEq(token.totalSupply(), 1000e18); }
    function test_BalanceOf() public view { assertEq(token.balanceOf(user1), 1000e18); }
    function test_BalanceOfZero() public view { assertEq(token.balanceOf(user2), 0); }

    // --- Проверки переводов (Transfers) ---
    function test_Transfer() public {
        vm.startPrank(user1);
        token.transfer(user2, 100e18);
        vm.stopPrank();
        assertEq(token.balanceOf(user1), 900e18);
        assertEq(token.balanceOf(user2), 100e18);
    }

    function test_TransferZero() public {
        vm.startPrank(user1);
        token.transfer(user2, 0);
        vm.stopPrank();
        assertEq(token.balanceOf(user1), 1000e18);
    }

    function test_TransferToSelf() public {
        vm.startPrank(user1);
        token.transfer(user1, 100e18);
        vm.stopPrank();
        assertEq(token.balanceOf(user1), 1000e18);
    }

    function test_RevertTransferInsufficientBalance() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.transfer(user2, 2000e18); // Больше, чем есть
        vm.stopPrank();
    }

    function test_RevertTransferToZeroAddress() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.transfer(address(0), 100e18);
        vm.stopPrank();
    }

    // --- Проверки прав доступа (Allowances) ---
    function test_Approve() public {
        vm.startPrank(user1);
        token.approve(user2, 500e18);
        vm.stopPrank();
        assertEq(token.allowance(user1, user2), 500e18);
    }

    function test_TransferFrom() public {
        vm.startPrank(user1);
        token.approve(user2, 500e18);
        vm.stopPrank();

        vm.startPrank(user2);
        token.transferFrom(user1, user2, 100e18);
        vm.stopPrank();

        assertEq(token.balanceOf(user2), 100e18);
        assertEq(token.allowance(user1, user2), 400e18);
    }

    function test_RevertTransferFromInsufficientAllowance() public {
        vm.startPrank(user1);
        token.approve(user2, 50e18);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert();
        token.transferFrom(user1, user2, 100e18); // Пытаемся снять больше разрешенного
        vm.stopPrank();
    }

    // --- Проверки DAO и голосования ---
    function test_DelegateToSelf() public {
        vm.startPrank(user1);
        token.delegate(user1);
        vm.stopPrank();
        assertEq(token.getVotes(user1), 1000e18);
    }

    function test_DelegateToOther() public {
        vm.startPrank(user1);
        token.delegate(user2);
        vm.stopPrank();
        assertEq(token.getVotes(user2), 1000e18);
        assertEq(token.getVotes(user1), 0);
    }

    function test_VotesTransferWithDelegation() public {
        vm.startPrank(user1);
        token.delegate(user1);
        token.transfer(user2, 100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        token.delegate(user2);
        vm.stopPrank();

        assertEq(token.getVotes(user1), 900e18);
        assertEq(token.getVotes(user2), 100e18);
    }
}