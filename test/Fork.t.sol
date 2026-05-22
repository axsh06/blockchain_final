// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PriceOracle} from "../src/PriceOracle.sol";

contract ForkTest is Test {
    PriceOracle oracle;
    // Адрес настоящего оракула Chainlink ETH/USD в тестовой сети SEPOLIA
    address constant SEPOLIA_ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function setUp() public {
        // ИСПОЛЬЗУЕМ СТАБИЛЬНЫЙ УЗЕЛ СЕТИ SEPOLIA
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com");
        oracle = new PriceOracle(SEPOLIA_ETH_USD_FEED);
    }

    // 1. Проверяем, что оракул реально отдает цену больше 0
    function test_Fork_OraclePriceIsPositive() public view {
        int256 price = oracle.getLatestPrice();
        assertTrue(price > 0, "Price should be positive");
    }

    // 2. Проверяем, что адрес фида сохранился верно
    function test_Fork_OracleFeedAddress() public view {
        assertEq(address(oracle.priceFeed()), SEPOLIA_ETH_USD_FEED);
    }

    // 3. Проверяем вызов к реальному контракту оракула (decimals)
    function test_Fork_OracleDecimals() public view {
        (bool success, bytes memory data) = SEPOLIA_ETH_USD_FEED.staticcall(abi.encodeWithSignature("decimals()"));
        assertTrue(success);
        uint8 decimals = abi.decode(data, (uint8));
        assertEq(decimals, 8); // У фидов Chainlink для USD всегда 8 decimals
    }
}
