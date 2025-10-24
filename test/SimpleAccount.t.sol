// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/SimpleAccount.sol";
import "../src/SimpleAccountFactory.sol";
import "@account-abstraction/contracts/core/EntryPoint.sol";
import "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract SimpleAccountTest is Test {
    SimpleAccount public account;
    SimpleAccountFactory public factory;
    EntryPoint public entryPoint;

    address public owner;
    uint256 public ownerKey;
    address public beneficiary;

    function setUp() public {
        // Create owner account
        ownerKey = 0xA11CE;
        owner = vm.addr(ownerKey);
        beneficiary = makeAddr("beneficiary");

        // Deploy EntryPoint
        entryPoint = new EntryPoint();

        // Deploy factory and create account
        factory = new SimpleAccountFactory(IEntryPoint(address(entryPoint)));
        account = factory.createAccount(owner, 0);

        // Fund the account
        vm.deal(address(account), 10 ether);
    }

    function testInitialization() public view {
        assertEq(account.owner(), owner);
        assertEq(address(account.entryPoint()), address(entryPoint));
    }

    function testExecuteAsOwner() public {
        vm.prank(owner);
        account.execute(beneficiary, 1 ether, "");
        assertEq(beneficiary.balance, 1 ether);
    }

    function testExecuteBatch() public {
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory datas = new bytes[](2);

        targets[0] = beneficiary;
        values[0] = 1 ether;
        datas[0] = "";

        targets[1] = beneficiary;
        values[1] = 0.5 ether;
        datas[1] = "";

        vm.prank(owner);
        account.executeBatch(targets, values, datas);
        assertEq(beneficiary.balance, 1.5 ether);
    }

    function testCannotExecuteAsNonOwner() public {
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert("SimpleAccount: not owner or entryPoint");
        account.execute(beneficiary, 1 ether, "");
    }

    function testTransferOwnership() public {
        address newOwner = makeAddr("newOwner");

        vm.prank(owner);
        account.transferOwnership(newOwner);

        assertEq(account.owner(), newOwner);
    }

    function testCannotTransferOwnershipToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("SimpleAccount: new owner is the zero address");
        account.transferOwnership(address(0));
    }

    function testAddDeposit() public {
        uint256 depositAmount = 1 ether;
        account.addDeposit{value: depositAmount}();
        assertEq(account.getDeposit(), depositAmount);
    }

    function testWithdrawDeposit() public {
        // Add deposit first
        uint256 depositAmount = 1 ether;
        account.addDeposit{value: depositAmount}();

        // Withdraw deposit
        address payable recipient = payable(makeAddr("recipient"));
        vm.prank(owner);
        account.withdrawDepositTo(recipient, depositAmount);

        assertEq(account.getDeposit(), 0);
        assertEq(recipient.balance, depositAmount);
    }

    function testReceiveEther() public {
        uint256 sendAmount = 1 ether;
        address sender = makeAddr("sender");
        vm.deal(sender, sendAmount);

        vm.prank(sender);
        (bool success,) = address(account).call{value: sendAmount}("");

        assertTrue(success);
        assertEq(address(account).balance, 10 ether + sendAmount);
    }
}
