// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {Timelock} from "../src/Timelock.sol";
import {ProtocolGovernor} from "../src/ProtocolGovernor.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

contract FinalCoverageTest is Test {
    GovToken token;
    Timelock timelock;
    ProtocolGovernor governor;
    YieldVault vault;

    address admin = address(this);
    address user = address(0x123);

    function setUp() public {
        token = new GovToken();
        token.mint(admin, 1000000e18);

        address[] memory proposers = new address[](1);
        proposers[0] = admin;
        address[] memory executors = new address[](1);
        executors[0] = admin;

        // Создаем контракты
        timelock = new Timelock(172800, proposers, executors, admin);
        governor = new ProtocolGovernor(IVotes(address(token)), timelock);
        vault = new YieldVault(token);
    }

    // --- DAO (Governor) Tests (10 тестов) ---
    function test_GovName() public view { assertEq(governor.name(), "ProtocolGovernor"); }
    function test_GovVersion() public view { assertEq(governor.version(), "1"); }
    function test_GovDelay() public view { assertEq(governor.votingDelay(), 86400); }
    function test_GovPeriod() public view { assertEq(governor.votingPeriod(), 604800); }
    function test_GovThreshold() public view { assertEq(governor.proposalThreshold(), 10000e18); }
    
    function test_GovQuorum() public { 
        vm.roll(block.number + 1); // Перематываем время на 1 блок вперед
        assertEq(governor.quorum(block.number - 1), 40000e18); 
    }
    
    function test_GovTokenAddress() public view { assertEq(address(governor.token()), address(token)); }
    function test_GovTimelockAddress() public view { assertEq(governor.timelock(), address(timelock)); }
    
    function test_RevertGovInvalidState() public {
        vm.expectRevert();
        governor.state(999); // Несуществующее предложение
    }
    
    function test_RevertGovProposeWithoutVotes() public {
        vm.prank(user); // У юзера 0 голосов
        address[] memory t = new address[](1);
        uint256[] memory v = new uint256[](1);
        bytes[] memory c = new bytes[](1);
        vm.expectRevert();
        governor.propose(t, v, c, "Fail");
    }

    // --- Timelock Security Tests (10 тестов) ---
    function test_TimeDelay() public view { assertEq(timelock.getMinDelay(), 172800); }
    function test_TimeAdminRole() public view { assertTrue(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), admin)); }
    function test_TimeProposerRole() public view { assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), admin)); }
    function test_TimeExecutorRole() public view { assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), admin)); }
    
    function test_TimeRevokeAdmin() public {
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), admin);
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), admin));
    }
    
    function test_RevertTimeScheduleUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        timelock.schedule(address(0), 0, "", bytes32(0), bytes32(0), 172800);
    }
    
    function test_RevertTimeExecuteUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        timelock.execute(address(0), 0, "", bytes32(0), bytes32(0));
    }
    
    function test_RevertTimeCancelUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        timelock.cancel(bytes32(0));
    }
    
    function test_RevertTimeDelayTooShort() public {
        vm.expectRevert();
        timelock.schedule(address(0), 0, "", bytes32(0), bytes32(0), 100); // 100 сек меньше 2 дней
    }
    
    function test_TimeHashOperation() public view {
        bytes32 hashId = timelock.hashOperation(address(0), 0, "", bytes32(0), bytes32(0));
        assertTrue(hashId != bytes32(0));
    }

    // --- Vault & Token Extra Tests (10 тестов) ---
    function test_VaultDecimals() public view { assertEq(vault.decimals(), 18); }
    function test_VaultMaxWithdraw() public view { assertEq(vault.maxWithdraw(user), 0); }
    function test_VaultMaxRedeem() public view { assertEq(vault.maxRedeem(user), 0); }
    function test_VaultPreviewDeposit() public view { assertEq(vault.previewDeposit(100), 100); }
    function test_VaultPreviewMint() public view { assertEq(vault.previewMint(100), 100); }
    function test_VaultPreviewWithdraw() public view { assertEq(vault.previewWithdraw(100), 100); }
    function test_VaultPreviewRedeem() public view { assertEq(vault.previewRedeem(100), 100); }
    
    function test_TokenDelegatesEmpty() public view { assertEq(token.delegates(user), address(0)); }
    
    function test_TokenPastVotes() public {
        vm.roll(block.number + 1); // Перематываем блок вперед для проверки прошлого баланса
        assertEq(token.getPastVotes(user, block.number - 1), 0);
    }
    
    function test_TokenPastTotalSupply() public {
        vm.roll(block.number + 1);
        assertEq(token.getPastTotalSupply(block.number - 1), 1000000e18);
    }
}