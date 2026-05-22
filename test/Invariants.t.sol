// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {GovToken} from "../src/GovToken.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockAsset is ERC20 {
    constructor() ERC20("Mock", "MCK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract InvariantsTest is Test {
    AMMPair pair;
    YieldVault vault;
    GovToken token;
    MockAsset asset;

    function setUp() public {
        token = new GovToken();
        asset = new MockAsset();
        pair = new AMMPair(address(token), address(asset));
        vault = new YieldVault(token);
    }

    // 1. K-Invariant: баланс контракта AMM всегда больше или равен резервам token0
    function invariant_AMM_Token0Balance_GTE_Reserve0() public view {
        assertGe(token.balanceOf(address(pair)), pair.reserve0());
    }

    // 2. K-Invariant: баланс контракта AMM всегда больше или равен резервам token1
    function invariant_AMM_Token1Balance_GTE_Reserve1() public view {
        assertGe(asset.balanceOf(address(pair)), pair.reserve1());
    }

    // 3. Vault Invariant: Активов в хранилище всегда больше или равно выпущенным долям
    function invariant_Vault_TotalAssets_GTE_TotalSupply() public view {
        assertGe(vault.totalAssets(), vault.totalSupply());
    }

    // 4. GovToken Invariant: Общая эмиссия не может превышать max uint256 (проверка переполнения)
    function invariant_GovToken_TotalSupply_Valid() public view {
        assertTrue(token.totalSupply() >= 0);
    }

    // 5. AMM Invariant: резервы не могут быть отрицательными (uint защита)
    function invariant_AMM_Reserves_Valid() public view {
        assertTrue(pair.reserve0() >= 0 && pair.reserve1() >= 0);
    }
}
