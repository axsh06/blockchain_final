// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PriceOracle} from "../src/PriceOracle.sol";

contract PriceOracleTest is Test {
    PriceOracle oracle;
    address dummyFeed = address(0x123);

    function setUp() public {
        oracle = new PriceOracle(dummyFeed);
    }

    function test_FeedAddressStored() public view {
        assertEq(address(oracle.priceFeed()), dummyFeed);
    }

    function test_RevertCallToInvalidFeed() public {
        // Вызов должен упасть, так как по адресу dummyFeed нет настоящего контракта
        vm.expectRevert();
        oracle.getLatestPrice();
    }

    function test_InitializationWithZeroAddress() public {
        PriceOracle zeroOracle = new PriceOracle(address(0));
        assertEq(address(zeroOracle.priceFeed()), address(0));
    }
}
