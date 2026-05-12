// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Интерфейс для подключения к Chainlink
interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PriceOracle {
    AggregatorV3Interface public priceFeed;

    // В конструктор передается адрес оракула нужной сети (например, ETH/USD в Sepolia)
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Функция возвращает актуальную цену с защитой от устаревших данных
    function getLatestPrice() public view returns (int256) {
        (
            /* uint80 roundId */,
            int256 price,
            /* uint256 startedAt */,
            uint256 updatedAt,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        
        // Требование безопасности: проверяем, что данные не старше 1 часа
        require(block.timestamp - updatedAt < 3600, "Oracle: Stale price data");
        require(price > 0, "Oracle: Invalid price");

        return price;
    }
}