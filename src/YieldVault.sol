// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract YieldVault is ERC4626 {
    
    constructor(IERC20 asset_) ERC4626(asset_) ERC20("DeFi Super Vault", "vDST") {}


}
 