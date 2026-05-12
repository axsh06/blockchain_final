// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    // В конструктор мы будем передавать 172800 секунд (это ровно 2 дня)
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}