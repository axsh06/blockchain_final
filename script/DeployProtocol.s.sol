// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {GovToken} from "../src/GovToken.sol";
import {Timelock} from "../src/Timelock.sol";
import {ProtocolGovernor} from "../src/ProtocolGovernor.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

// Создаем тестовый стейблкоин для второй половины пула AMM
contract MockUSD is ERC20 {
    constructor() ERC20("Mock USD", "mUSD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract DeployProtocol is Script {
    function run() external {
        // Стандартный приватный ключ для локальной тестовой сети Anvil
        uint256 deployerPrivateKey =
            vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        vm.startBroadcast(deployerPrivateKey);

        // 1. Деплоим токен управления
        GovToken govToken = new GovToken();
        console.log("1. GovToken deployed at:", address(govToken));

        // 2. Деплоим Timelock (задержка 2 дня)
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        Timelock timelock = new Timelock(172800, proposers, executors, msg.sender);
        console.log("2. Timelock deployed at:", address(timelock));

        // 3. Деплоим DAO
        ProtocolGovernor governor = new ProtocolGovernor(IVotes(address(govToken)), timelock);
        console.log("3. ProtocolGovernor deployed at:", address(governor));

        // Выдаем права DAO
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        // 4. Деплоим второй токен для пула (mUSD)
        MockUSD mUsd = new MockUSD();
        console.log("4. MockUSD deployed at:", address(mUsd));

        // 5. Деплоим AMM пулл (GovToken / mUSD)
        AMMPair amm = new AMMPair(address(govToken), address(mUsd));
        console.log("5. AMMPair deployed at:", address(amm));

        // 6. Деплоим YieldVault
        YieldVault vault = new YieldVault(govToken);
        console.log("6. YieldVault deployed at:", address(vault));

        vm.stopBroadcast();
    }
}
