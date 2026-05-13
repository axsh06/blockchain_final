// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AMMFactory.sol";
import "../src/AMMPair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}

contract AMMFactoryTest is Test {
    AMMFactory factory;
    MockToken tokenA;
    MockToken tokenB;

    function setUp() public {
        factory = new AMMFactory();
        tokenA = new MockToken("Token A", "TKNA");
        tokenB = new MockToken("Token B", "TKNB");
    }

    function test_CreatePair() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));

        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
        assertTrue(pair != address(0));
    }

    function test_CreatePairDeterministic() public {
        bytes32 salt = keccak256(abi.encodePacked("salt123"));
        address pair = factory.createPairDeterministic(address(tokenA), address(tokenB), salt);

        assertTrue(pair != address(0));
        assertEq(factory.allPairsLength(), 1);

        vm.expectRevert();
        factory.createPairDeterministic(address(tokenA), address(tokenB), salt);
    }

    function test_RevertIfIdenticalTokens() public {
        vm.expectRevert("IDENTICAL_ADDRESSES");
        factory.createPair(address(tokenA), address(tokenA));
    }
}
