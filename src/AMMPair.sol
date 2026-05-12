// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract AMMPair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    constructor(address _token0, address _token1) ERC20("AMM LP Token", "AMMLP") {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    // Функция обмена (Swap) с комиссией 0.3% и защитой от проскальзывания (minAmountOut)
    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) external nonReentrant returns (uint256 amountOut) {
        require(tokenIn == address(token0) || tokenIn == address(token1), "Invalid token");
        require(amountIn > 0, "Zero amount");

        bool isToken0 = tokenIn == address(token0);
        (IERC20 tokenInContract, IERC20 tokenOutContract, uint256 reserveIn, uint256 reserveOut) = isToken0
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);

        // Расчет по формуле постоянного произведения (x * y = k) с комиссией 0.3%
        uint256 amountInWithFee = amountIn * 997;
        amountOut = (reserveOut * amountInWithFee) / ((reserveIn * 1000) + amountInWithFee);

        // Защита от проскальзывания (Slippage protection)
        require(amountOut >= minAmountOut, "Slippage protection triggered");

        tokenInContract.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenOutContract.safeTransfer(msg.sender, amountOut);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
    }
}