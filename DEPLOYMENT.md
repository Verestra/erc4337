# Lisk Sepolia Deployment

## Deployed Contracts

- **Network**: Lisk Sepolia Testnet
- **Chain ID**: 4202
- **Deployment Date**: October 24, 2025

### Contract Addresses

| Contract | Address |
|----------|---------|
| SimpleAccountFactory | `0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F` |
| SimpleAccount (Implementation) | `0x826224A88d942Cc4E0341E18A2831EF7fFeA1500` |
| EntryPoint | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |

### Transaction Details

- **Deployment Transaction**: `0xdb675312f1d9e1bff6f5a1ad11d329f9f3428f4e333b1078abe1b7b734539aeb`
- **Block Number**: 28004571
- **Gas Used**: 2,170,390
- **Gas Price**: 0.001000253 gwei

### Explorer Links

- [Factory Contract](https://sepolia-blockscout.lisk.com/address/0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F)
- [Implementation Contract](https://sepolia-blockscout.lisk.com/address/0x826224A88d942Cc4E0341E18A2831EF7fFeA1500)
- [Deployment Transaction](https://sepolia-blockscout.lisk.com/tx/0xdb675312f1d9e1bff6f5a1ad11d329f9f3428f4e333b1078abe1b7b734539aeb)

## How to Use

### Creating a Smart Account

```javascript
// Using ethers.js or web3.js
const factoryAddress = "0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F";
const factory = new ethers.Contract(factoryAddress, factoryABI, signer);

// Create account for owner with salt 0
const ownerAddress = "0x..."; // Your EOA address
const salt = 0;
const tx = await factory.createAccount(ownerAddress, salt);
await tx.wait();

// Get the created account address
const accountAddress = await factory.getAddress(ownerAddress, salt);
console.log("Smart Account:", accountAddress);
```

### Interacting with Your Account

```javascript
// Execute a transaction
const account = new ethers.Contract(accountAddress, accountABI, signer);

// Send ETH
await account.execute(
    recipientAddress,
    ethers.parseEther("0.1"),
    "0x"
);

// Execute batch transactions
const targets = [address1, address2];
const values = [0, 0];
const datas = [data1, data2];
await account.executeBatch(targets, values, datas);
```

### Using Cast (Foundry CLI)

```bash
# Get account address (counterfactual)
cast call 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F \
  "getAddress(address,uint256)" \
  <owner_address> \
  0 \
  --rpc-url https://rpc.sepolia-api.lisk.com

# Create account
cast send 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F \
  "createAccount(address,uint256)" \
  <owner_address> \
  0 \
  --rpc-url https://rpc.sepolia-api.lisk.com \
  --private-key $PRIVATE_KEY
```

## Verification

### ✅ Contracts Successfully Verified!

Both contracts have been verified on Blockscout using the proper verifier:

```bash
# Verify SimpleAccountFactory
forge verify-contract 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F \
  ./src/SimpleAccountFactory.sol:SimpleAccountFactory \
  --chain 4202 \
  --watch \
  --verifier blockscout \
  --verifier-url https://sepolia-blockscout.lisk.com/api \
  --constructor-args $(cast abi-encode "constructor(address)" 0x0000000071727De22E5E9d8BAf0edAc6f37da032)

# Verify SimpleAccount
forge verify-contract 0x826224A88d942Cc4E0341E18A2831EF7fFeA1500 \
  ./src/SimpleAccount.sol:SimpleAccount \
  --chain 4202 \
  --watch \
  --verifier blockscout \
  --verifier-url https://sepolia-blockscout.lisk.com/api \
  --constructor-args $(cast abi-encode "constructor(address)" 0x0000000071727De22E5E9d8BAf0edAc6f37da032)
```

You can now interact with the contracts on Blockscout's "Read Contract" and "Write Contract" tabs!

## Testing

### ✅ Test Smart Account Created

A test smart account has been successfully created:

- **Smart Account Address**: `0x34e187b50054861561927ac24f6995f54ec931c8`
- **Owner**: `0x67BA06dB6d9c562857BF08AB1220a16DfA455c45`
- **Creation Transaction**: `0x6e3f40404bdc1b0f8551ac5ac2db7b57f5664b0f6abc52c5e675e94c7a4bddc6`
- **View on Explorer**: [Smart Account](https://sepolia-blockscout.lisk.com/address/0x34e187b50054861561927ac24f6995f54ec931c8)

### Test Your Deployed Contracts

```bash
# Check factory deployment
cast call 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F \
  "accountImplementation()" \
  --rpc-url https://rpc.sepolia-api.lisk.com
# Expected output: 0x000000000000000000000000826224a88d942cc4e0341e18a2831ef7ffea1500

# Check smart account owner
cast call 0x34e187b50054861561927ac24f6995f54ec931c8 \
  "owner()" \
  --rpc-url https://rpc.sepolia-api.lisk.com
# Expected output: 0x00000000000000000000000067ba06db6d9c562857bf08ab1220a16dfa455c45

# Check smart account entryPoint
cast call 0x34e187b50054861561927ac24f6995f54ec931c8 \
  "entryPoint()" \
  --rpc-url https://rpc.sepolia-api.lisk.com
# Expected output: 0x0000000000000000000000000000000071727de22e5e9d8baf0edac6f37da032
```

## Next Steps

1. ✅ Contracts deployed successfully
2. ✅ Contracts verified on Blockscout
3. ✅ Test smart account created
4. 🚀 Create more smart accounts for your users
5. 🧪 Test advanced account functionalities (batch transactions, deposits, etc.)
6. 📱 Integrate with your dApp frontend
7. 🔐 Implement signature validation for UserOperations
8. 💰 Set up gas sponsorship via Paymasters (optional)

## Support

- **Lisk Docs**: https://docs.lisk.com
- **Block Explorer**: https://sepolia-blockscout.lisk.com
- **Faucet**: https://sepolia-faucet.lisk.com

## Security Notice

⚠️ This is a testnet deployment. DO NOT use these contracts with real funds on mainnet without proper auditing.
