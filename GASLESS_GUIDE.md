# How to Enable Gasless Transactions (Gas Sponsorship)

## Why Am I Paying Gas?

When you use the frontend demo directly, your **MetaMask wallet pays gas** because:
- You're calling the smart account contract directly from your EOA (Externally Owned Account)
- This is the "direct call" method, not full ERC-4337 flow

## The Solution: Backend Bundler with Gas Sponsorship

To make transactions gasless for users, you need:

1. **Backend Bundler**: Collects UserOperations and submits them
2. **Backend Wallet**: Pays gas on behalf of users
3. **Modified Frontend**: Signs UserOperations instead of direct calls

---

## Quick Setup: Gasless Account Creation

The easiest way to start is to make **account creation** gasless:

### 1. Start Your Backend API

```bash
cd examples/backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Add your backend wallet private key (wallet that will pay gas)
echo "BACKEND_PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE" > .env

# Start the server
npm start
```

Your backend should show:
```
🚀 ERC-4337 Backend API running on port 3000
💼 Backend Wallet: 0x...
```

### 2. Test Gasless Account Creation

```bash
# Create account - Backend pays gas, user doesn't!
curl -X POST http://localhost:3000/api/account/create \
  -H "Content-Type: application/json" \
  -d '{"owner": "0x296f9f84468d4E5758b5Af2A253d617b67D8cAC86", "salt": 5}'
```

Response:
```json
{
  "success": true,
  "accountAddress": "0x...",
  "transactionHash": "0x...",
  "gasUsed": "174612",
  "message": "Backend paid for gas!"
}
```

**User paid: 0 ETH** ✅
**Backend paid: 0.000174 ETH** (from backend wallet)

---

## Full Gasless Flow: Execute Transactions

For full gasless transactions (sending ETH, calling contracts), you need to implement UserOperations:

### 3. Install Required Dependencies

```bash
cd examples/frontend-gasless
npm install ethers @account-abstraction/sdk
```

### 4. Create Gasless Transaction Helper

Create `examples/frontend-gasless/gasless-helper.js`:

```javascript
import { ethers } from 'ethers';

const BUNDLER_URL = 'http://localhost:3000/api/sendUserOp';
const ACCOUNT_ADDRESS = '0x6a7F68D6Dc3f16E37c450c23503cA30Acb906741'; // Your smart account

async function sendGaslessTransaction(recipient, amount, signer) {
  const account = new ethers.Contract(
    ACCOUNT_ADDRESS,
    ['function execute(address,uint256,bytes)', 'function getNonce() view returns (uint256)'],
    ethers.provider
  );

  // 1. Build the call data
  const callData = account.interface.encodeFunctionData('execute', [
    recipient,
    ethers.utils.parseEther(amount),
    '0x'
  ]);

  // 2. Create UserOperation
  const nonce = await account.getNonce();
  const userOp = {
    sender: ACCOUNT_ADDRESS,
    nonce: nonce.toString(),
    callData,
    callGasLimit: '100000',
    verificationGasLimit: '150000',
    preVerificationGas: '21000',
    maxFeePerGas: '2000000000',
    maxPriorityFeePerGas: '1000000000'
  };

  // 3. Sign UserOperation (off-chain, free!)
  const userOpHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ['address', 'uint256', 'bytes'],
      [userOp.sender, userOp.nonce, userOp.callData]
    )
  );

  const signature = await signer.signMessage(ethers.utils.arrayify(userOpHash));
  userOp.signature = signature;

  // 4. Send to bundler (bundler pays gas!)
  const response = await fetch(BUNDLER_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userOp })
  });

  const result = await response.json();

  if (result.success) {
    console.log('✅ Transaction sent! Gas paid by bundler');
    console.log('Transaction hash:', result.txHash);
    return result.txHash;
  } else {
    throw new Error(result.error);
  }
}

// Usage
const signer = await provider.getSigner();
await sendGaslessTransaction('0xRecipient...', '0.001', signer);
// User paid: 0 ETH ✅
// Backend paid: ~0.0001 ETH
```

---

## Option B: Use Public Bundlers (Recommended for Production)

Instead of running your own bundler, use services like:

### 1. Alchemy (Recommended)

```bash
npm install @alchemy/aa-core @alchemy/aa-accounts
```

```javascript
import { AlchemyProvider } from '@alchemy/aa-alchemy';
import { LightSmartContractAccount } from '@alchemy/aa-accounts';

const provider = new AlchemyProvider({
  apiKey: 'YOUR_ALCHEMY_API_KEY',
  chain: liskSepolia,
  entryPointAddress: '0x0000000071727De22E5E9d8BAf0edAc6f37da032'
});

// Send gasless transaction
const result = await provider.sendUserOperation({
  target: recipient,
  data: '0x',
  value: ethers.utils.parseEther('0.001')
});
// Alchemy handles bundling and optionally gas sponsorship!
```

### 2. Pimlico

```bash
npm install permissionless viem
```

```javascript
import { createPimlicoBundlerClient } from 'permissionless/clients/pimlico';

const bundlerClient = createPimlicoBundlerClient({
  transport: http('https://api.pimlico.io/v1/lisk-sepolia/rpc?apikey=YOUR_KEY'),
  entryPoint: '0x0000000071727De22E5E9d8BAf0edAc6f37da032'
});

// Send user operation
const userOpHash = await bundlerClient.sendUserOperation({ ... });
// Pimlico pays gas!
```

---

## Comparison

| Method | Who Pays Gas? | Complexity | Use Case |
|--------|---------------|------------|----------|
| **Direct Call** (Current) | User (MetaMask) | ⭐ Easy | Testing, simple dApps |
| **Your Backend Bundler** | Your backend wallet | ⭐⭐ Medium | Custom control, learning |
| **Public Bundler** (Alchemy/Pimlico) | Their service (with API key) | ⭐⭐⭐ Easy with SDK | Production apps |

---

## Quick Win: Make Account Creation Gasless Now!

Modify your frontend to use backend API for account creation:

```javascript
// OLD: User pays gas
const tx = await factory.createAccount(userAddress, salt);
await tx.wait();

// NEW: Backend pays gas
const response = await fetch('http://localhost:3000/api/account/create', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ owner: userAddress, salt })
});

const { accountAddress } = await response.json();
// User paid: 0 ETH ✅
```

---

## Summary

**Why you're paying gas now:**
- Using "direct call" method (MetaMask → Smart Account)
- This is normal and works fine for many use cases

**To make it gasless:**

1. **Easiest**: Use backend API for account creation (already built!)
2. **Medium**: Implement full UserOperation flow with your bundler
3. **Best for production**: Use Alchemy/Pimlico bundler services

**Next steps:**
1. Start with making account creation gasless (backend API)
2. Keep transactions direct for now (simple)
3. Later: Add full UserOperation support for all transactions

---

## Resources

- **Your Backend API**: `examples/backend/` (already created!)
- **Alchemy AA SDK**: https://accountkit.alchemy.com/
- **Pimlico Docs**: https://docs.pimlico.io/
- **ERC-4337 Spec**: https://eips.ethereum.org/EIPS/eip-4337

**The beauty of ERC-4337: You can start simple (paying gas) and gradually add gasless features as needed!**
