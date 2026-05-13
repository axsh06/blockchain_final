// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ProtocolGovernor} from "../src/ProtocolGovernor.sol";
import {Timelock} from "../src/Timelock.sol";
import {GovToken} from "../src/GovToken.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";
import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

contract Box {
    uint256 public value;
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function store(uint256 newValue) public {
        require(msg.sender == owner, "Only owner (DAO) can call");
        value = newValue;
    }
}

contract GovernorTest is Test {
    ProtocolGovernor governor;
    Timelock timelock;
    GovToken token;
    Box box;

    address public user = address(1);
    uint256 public constant INITIAL_SUPPLY = 1000000e18;

    address[] proposers;
    address[] executors;

    function setUp() public {
        token = new GovToken();
        token.mint(user, INITIAL_SUPPLY);

        proposers = new address[](0);
        executors = new address[](0);
        timelock = new Timelock(172800, proposers, executors, address(this));

        governor = new ProtocolGovernor(IVotes(address(token)), timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));

        box = new Box(address(timelock));
    }

    function test_FullGovernanceLifecycle() public {
        vm.startPrank(user);
        token.delegate(user);
        vm.stopPrank();

        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(box);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("store(uint256)", 888);

        string memory description = "Proposal #1: Store 888 in Box";

        vm.prank(user);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // ИСПРАВЛЕНИЕ: Берем точную задержку из контракта и мотаем на нее и время, и блоки
        uint256 delay = governor.votingDelay();
        vm.warp(block.timestamp + delay + 1);
        vm.roll(block.number + delay + 1);

        vm.prank(user);
        governor.castVote(proposalId, 1);

        // ИСПРАВЛЕНИЕ: Мотаем период голосования аналогично
        uint256 period = governor.votingPeriod();
        vm.warp(block.timestamp + period + 1);
        vm.roll(block.number + period + 1);

        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // Задержка Timelock (2 дня = 172800 сек)
        vm.warp(block.timestamp + 172801);
        vm.roll(block.number + 172801);

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(box.value(), 888);
    }
}
