# ERC-4337 Account Abstraction with Foundry

A minimal implementation of ERC-4337 (Account Abstraction) smart contract wallets using Foundry.

## Overview

This project implements a simple smart contract account system following the ERC-4337 standard. It includes:

- **SimpleAccount**: A minimal smart contract account with single-owner authorization
- **SimpleAccountFactory**: A factory contract for creating accounts using CREATE2 for deterministic addresses
- Comprehensive test suite
- Deployment scripts

## Features

- Single owner authorization using ECDSA signatures
- Execute single or batch transactions
- UUPS upgradeable pattern
- Deterministic account addresses via CREATE2
- EntryPoint integration for account abstraction
- Deposit management for gas sponsorship

## Project Structure

```
├── src/
│   ├── SimpleAccount.sol           # Main account contract
│   └── SimpleAccountFactory.sol    # Factory for creating accounts
├── test/
│   ├── SimpleAccount.t.sol         # Account tests
│   └── SimpleAccountFactory.t.sol  # Factory tests
├── script/
│   └── DeploySimpleAccountFactory.s.sol  # Deployment script
└── foundry.toml                    # Foundry configuration
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.23

## Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd erc4337
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

## Testing

Run all tests:
```bash
forge test
```

Run tests with verbosity:
```bash
forge test -vv
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

## Deployment

### Local Development

1. Start a local Anvil node:
```bash
anvil
```

2. Deploy the contracts:
```bash
forge script script/DeploySimpleAccountFactory.s.sol:DeploySimpleAccountFactory --fork-url http://localhost:8545 --broadcast
```

### Testnet/Mainnet Deployment

1. Set up your environment variables:
```bash
export PRIVATE_KEY=your_private_key
export ENTRYPOINT_ADDRESS=0x0000000071727De22E5E9d8BAf0edAc6f37da032  # Optional, uses default if not set
```

2. Deploy to network:
```bash
forge script script/DeploySimpleAccountFactory.s.sol:DeploySimpleAccountFactory \
  --rpc-url <your_rpc_url> \
  --broadcast \
  --verify
```

## Usage

### Creating an Account

```solidity
// Get the factory instance
SimpleAccountFactory factory = SimpleAccountFactory(factoryAddress);

// Create an account for an owner with a salt
address owner = 0x...;
uint256 salt = 0;
SimpleAccount account = factory.createAccount(owner, salt);
```

### Executing Transactions

```solidity
// Execute a single transaction
account.execute(targetAddress, value, data);

// Execute batch transactions
address[] memory targets = new address[](2);
uint256[] memory values = new uint256[](2);
bytes[] memory datas = new bytes[](2);

targets[0] = address1;
values[0] = 1 ether;
datas[0] = abi.encodeWithSignature("transfer(address,uint256)", recipient, amount);

targets[1] = address2;
values[1] = 0;
datas[1] = abi.encodeWithSignature("approve(address,uint256)", spender, amount);

account.executeBatch(targets, values, datas);
```

### Managing Deposits

```solidity
// Add deposit to EntryPoint
account.addDeposit{value: 1 ether}();

// Check deposit
uint256 deposit = account.getDeposit();

// Withdraw deposit
account.withdrawDepositTo(payable(recipient), amount);
```

## Contract Addresses

### EntryPoint v0.7
- **Ethereum Mainnet**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
- **Sepolia Testnet**: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

## Security Considerations

This is a minimal implementation for educational purposes. Before using in production:

1. Conduct thorough security audits
2. Implement additional security features (rate limiting, multi-sig, etc.)
3. Add comprehensive access controls
4. Consider using battle-tested implementations like [eth-infinitism/account-abstraction](https://github.com/eth-infinitism/account-abstraction)

## Dependencies

- [account-abstraction](https://github.com/eth-infinitism/account-abstraction) v0.7.0 - ERC-4337 EntryPoint and interfaces
- [openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) v5.4.0 - Utility contracts
- [forge-std](https://github.com/foundry-rs/forge-std) - Foundry testing utilities

## Resources

- [ERC-4337 Specification](https://eips.ethereum.org/EIPS/eip-4337)
- [Account Abstraction Documentation](https://docs.alchemy.com/docs/account-abstraction-overview)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT
