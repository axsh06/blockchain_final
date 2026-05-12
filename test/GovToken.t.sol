// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";

contract GovTokenTest is Test {
    GovToken public token;

    function setUp() public {
        token = new GovToken();
    }

    function testMint() public {
        token.mint(address(1), 1000);
        assertEq(token.balanceOf(address(1)), 1000);
    }
}