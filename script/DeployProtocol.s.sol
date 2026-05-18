// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {GovToken} from "../src/GovToken.sol";
import {Timelock} from "../src/Timelock.sol";
import {ProtocolGovernor} from "../src/ProtocolGovernor.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {PriceOracle} from "../src/PriceOracle.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

contract DeployProtocol is Script {
    function run() external {
        uint256 deployerPrivateKey =
            vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Деплоим токены
        GovToken govToken = new GovToken();

        // 2. Деплоим Timelock
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        Timelock timelock = new Timelock(172800, proposers, executors, deployer);

        // 3. Деплоим DAO
        ProtocolGovernor governor = new ProtocolGovernor(IVotes(address(govToken)), timelock);

        // 4. Настройка ролей в Timelock
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, deployer);

        // 5. Деплоим AMM и Vault
        AMMPair amm = new AMMPair(address(govToken), address(0));
        YieldVault vault = new YieldVault(govToken);

        // 6. Оракул для Sepolia
        PriceOracle oracle = new PriceOracle(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        console.log("Governor deployed at:", address(governor));
        console.log("Timelock deployed at:", address(timelock));

        vm.stopBroadcast();
    }
}
