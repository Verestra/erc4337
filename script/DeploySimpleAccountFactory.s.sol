// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/SimpleAccountFactory.sol";
import "@account-abstraction/contracts/core/EntryPoint.sol";

/**
 * @title DeploySimpleAccountFactory
 * @dev Deployment script for SimpleAccountFactory
 *
 * Usage:
 * forge script script/DeploySimpleAccountFactory.s.sol:DeploySimpleAccountFactory --rpc-url <your_rpc_url> --broadcast --verify
 *
 * For local testing:
 * forge script script/DeploySimpleAccountFactory.s.sol:DeploySimpleAccountFactory --fork-url http://localhost:8545 --broadcast
 */
contract DeploySimpleAccountFactory is Script {
    // EntryPoint addresses for different networks
    // Mainnet/Sepolia/etc. EntryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032
    address constant ENTRYPOINT_V07 = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address entryPoint = vm.envOr("ENTRYPOINT_ADDRESS", ENTRYPOINT_V07);

        vm.startBroadcast(deployerPrivateKey);

        // Check if EntryPoint exists at the address
        if (entryPoint.code.length == 0) {
            console.log("EntryPoint not found at address, deploying new EntryPoint...");
            EntryPoint newEntryPoint = new EntryPoint();
            entryPoint = address(newEntryPoint);
            console.log("EntryPoint deployed at:", entryPoint);
        } else {
            console.log("Using existing EntryPoint at:", entryPoint);
        }

        // Deploy SimpleAccountFactory
        SimpleAccountFactory factory = new SimpleAccountFactory(IEntryPoint(entryPoint));

        console.log("SimpleAccountFactory deployed at:", address(factory));
        console.log("Account implementation deployed at:", address(factory.accountImplementation()));

        vm.stopBroadcast();

        // Log deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("EntryPoint:", entryPoint);
        console.log("SimpleAccountFactory:", address(factory));
        console.log("SimpleAccount Implementation:", address(factory.accountImplementation()));
    }
}
