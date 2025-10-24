// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/SimpleAccount.sol";
import "../src/SimpleAccountFactory.sol";
import "@account-abstraction/contracts/core/EntryPoint.sol";

contract SimpleAccountFactoryTest is Test {
    SimpleAccountFactory public factory;
    EntryPoint public entryPoint;

    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        entryPoint = new EntryPoint();
        factory = new SimpleAccountFactory(IEntryPoint(address(entryPoint)));
    }

    function testCreateAccount() public {
        uint256 salt = 0;
        SimpleAccount account = factory.createAccount(owner, salt);

        assertEq(account.owner(), owner);
        assertEq(address(account.entryPoint()), address(entryPoint));
    }

    function testCreateAccountWithDifferentSalts() public {
        SimpleAccount account1 = factory.createAccount(owner, 0);
        SimpleAccount account2 = factory.createAccount(owner, 1);

        assertTrue(address(account1) != address(account2));
    }

    function testCreateAccountDeterministic() public {
        uint256 salt = 42;
        address predicted = factory.getAddress(owner, salt);
        SimpleAccount account = factory.createAccount(owner, salt);

        assertEq(address(account), predicted);
    }

    function testCreateAccountIdempotent() public {
        uint256 salt = 0;
        SimpleAccount account1 = factory.createAccount(owner, salt);
        SimpleAccount account2 = factory.createAccount(owner, salt);

        assertEq(address(account1), address(account2));
    }

    function testGetAddressBeforeCreation() public view {
        uint256 salt = 999;
        address predicted = factory.getAddress(owner, salt);

        assertTrue(predicted != address(0));
    }

    function testMultipleAccountsForDifferentOwners() public {
        address owner2 = makeAddr("owner2");
        uint256 salt = 0;

        SimpleAccount account1 = factory.createAccount(owner, salt);
        SimpleAccount account2 = factory.createAccount(owner2, salt);

        assertTrue(address(account1) != address(account2));
        assertEq(account1.owner(), owner);
        assertEq(account2.owner(), owner2);
    }
}
