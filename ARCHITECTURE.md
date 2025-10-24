# ERC-4337 Architecture & Usage Guide

## Overview

ERC-4337 Account Abstraction enables smart contract wallets without requiring changes to the Ethereum protocol. Here's how the components work together:

```
┌─────────────┐
│  Frontend   │ (React/Vue/etc)
│   (dApp)    │ - User interactions
│             │ - Sign UserOperations
│             │ - Display account info
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Backend   │ (Node.js/Python/etc) - OPTIONAL
│  (Bundler)  │ - Collect UserOperations
│             │ - Submit to EntryPoint
│             │ - Gas sponsorship (Paymaster)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Blockchain│
│             │
│ ┌─────────────────────────────────┐
│ │ EntryPoint (0x0000...7da032)    │
│ │ - Validates UserOperations      │
│ │ - Manages gas payments          │
│ └─────────────┬───────────────────┘
│               │
│ ┌─────────────▼──────────────────┐
│ │ SimpleAccountFactory           │
│ │ - Creates new smart accounts   │
│ │ - Deterministic addresses      │
│ └─────────────┬──────────────────┘
│               │
│ ┌─────────────▼──────────────────┐
│ │ SimpleAccount (Your Wallet)    │
│ │ - Stores assets (ETH, tokens)  │
│ │ - Executes transactions        │
│ │ - Validates signatures         │
│ └────────────────────────────────┘
└─────────────┘
```

## Components Breakdown

### 1. Smart Contracts (On-Chain) ✅ Already Deployed

**Your Deployed Contracts:**
- `SimpleAccountFactory`: `0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F`
- `SimpleAccount`: `0x826224A88d942Cc4E0341E18A2831EF7fFeA1500` (implementation)
- `EntryPoint`: `0x0000000071727De22E5E9d8BAf0edAc6f37da032`

**What they do:**
- Store user assets (ETH, NFTs, tokens)
- Execute transactions on behalf of users
- Validate signatures
- Handle gas payments

**When to use:**
- These are already deployed! You interact with them, not deploy them again
- Each user gets their own SimpleAccount instance (wallet)

---

### 2. Frontend (User Interface)

**Technologies:**
- React, Vue, Next.js, vanilla JavaScript
- ethers.js or viem for blockchain interaction
- Wagmi (optional, for React)

**What the frontend does:**
1. Create new smart accounts for users
2. Sign UserOperations with user's private key
3. Display account balance and transactions
4. Submit UserOperations to bundler or directly to EntryPoint

**Example: Creating a Smart Account**

```typescript
// frontend/createAccount.ts
import { ethers } from 'ethers';

const FACTORY_ADDRESS = '0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F';
const RPC_URL = 'https://rpc.sepolia-api.lisk.com';

async function createSmartAccount(userEOA: string) {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(privateKey, provider);

  const factoryABI = [
    'function createAccount(address owner, uint256 salt) returns (address)',
    'function getAddress(address owner, uint256 salt) view returns (address)'
  ];

  const factory = new ethers.Contract(FACTORY_ADDRESS, factoryABI, signer);

  // Get counterfactual address (address before deployment)
  const smartAccountAddress = await factory.getAddress(userEOA, 0);
  console.log('Your smart account address:', smartAccountAddress);

  // Create the account on-chain
  const tx = await factory.createAccount(userEOA, 0);
  await tx.wait();

  return smartAccountAddress;
}
```

**Example: Executing Transactions**

```typescript
// frontend/executeTransaction.ts
import { ethers } from 'ethers';

const ACCOUNT_ADDRESS = '0x34e187b50054861561927ac24f6995f54ec931c8'; // User's smart account

async function sendEther(recipient: string, amount: string) {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(ownerPrivateKey, provider);

  const accountABI = [
    'function execute(address dest, uint256 value, bytes calldata func)',
  ];

  const account = new ethers.Contract(ACCOUNT_ADDRESS, accountABI, signer);

  // Send 0.1 ETH to recipient
  const tx = await account.execute(
    recipient,
    ethers.parseEther(amount),
    '0x' // empty calldata for simple ETH transfer
  );

  await tx.wait();
  console.log('Transaction sent!');
}
```

**Example: React Component**

```tsx
// frontend/components/SmartWallet.tsx
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

export function SmartWallet() {
  const [smartAccount, setSmartAccount] = useState('');
  const [balance, setBalance] = useState('0');

  const FACTORY_ADDRESS = '0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F';

  async function createAccount() {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const userAddress = await signer.getAddress();

    const factory = new ethers.Contract(
      FACTORY_ADDRESS,
      ['function createAccount(address,uint256) returns (address)'],
      signer
    );

    const tx = await factory.createAccount(userAddress, 0);
    await tx.wait();

    // Get the account address
    const accountAddr = await factory.getAddress(userAddress, 0);
    setSmartAccount(accountAddr);
  }

  useEffect(() => {
    async function getBalance() {
      if (smartAccount) {
        const provider = new ethers.JsonRpcProvider(
          'https://rpc.sepolia-api.lisk.com'
        );
        const bal = await provider.getBalance(smartAccount);
        setBalance(ethers.formatEther(bal));
      }
    }
    getBalance();
  }, [smartAccount]);

  return (
    <div>
      <h2>Your Smart Wallet</h2>
      {!smartAccount ? (
        <button onClick={createAccount}>Create Smart Account</button>
      ) : (
        <div>
          <p>Address: {smartAccount}</p>
          <p>Balance: {balance} ETH</p>
        </div>
      )}
    </div>
  );
}
```

---

### 3. Backend (Optional - Bundler Service)

**Technologies:**
- Node.js, Python, Go
- Express/Fastify (for API)
- ethers.js or web3.py

**What the backend does:**
1. **Bundler**: Collects UserOperations from multiple users and submits them to EntryPoint
2. **Paymaster**: Sponsors gas fees for users (optional)
3. **API**: Provides endpoints for account creation, transaction history, etc.

**When you need a backend:**
- ✅ When you want to sponsor gas fees for users (Paymaster)
- ✅ When you want to batch multiple transactions together
- ✅ When you want to provide APIs for your dApp
- ✅ When you want to run a public bundler service
- ❌ NOT needed for basic account abstraction (users can interact directly with contracts)

**Example: Simple Bundler Service**

```typescript
// backend/bundler.ts
import express from 'express';
import { ethers } from 'ethers';

const app = express();
app.use(express.json());

const ENTRYPOINT_ADDRESS = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';
const provider = new ethers.JsonRpcProvider('https://rpc.sepolia-api.lisk.com');
const bundlerWallet = new ethers.Wallet(process.env.BUNDLER_PRIVATE_KEY!, provider);

// Endpoint to submit UserOperation
app.post('/api/sendUserOp', async (req, res) => {
  const { userOp } = req.body;

  try {
    const entryPoint = new ethers.Contract(
      ENTRYPOINT_ADDRESS,
      ['function handleOps(tuple[] ops, address beneficiary)'],
      bundlerWallet
    );

    // Submit to EntryPoint
    const tx = await entryPoint.handleOps([userOp], bundlerWallet.address);
    const receipt = await tx.wait();

    res.json({ success: true, txHash: receipt.hash });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Bundler running on port 3000');
});
```

**Example: Account Creation API**

```typescript
// backend/api.ts
import express from 'express';
import { ethers } from 'ethers';

const app = express();
app.use(express.json());

const FACTORY_ADDRESS = '0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F';
const provider = new ethers.JsonRpcProvider('https://rpc.sepolia-api.lisk.com');
const backendWallet = new ethers.Wallet(process.env.BACKEND_PRIVATE_KEY!, provider);

// Endpoint to create account for user (gas sponsored by backend)
app.post('/api/createAccount', async (req, res) => {
  const { ownerAddress } = req.body;

  try {
    const factory = new ethers.Contract(
      FACTORY_ADDRESS,
      [
        'function createAccount(address,uint256) returns (address)',
        'function getAddress(address,uint256) view returns (address)'
      ],
      backendWallet
    );

    // Check if account already exists
    const predictedAddress = await factory.getAddress(ownerAddress, 0);
    const code = await provider.getCode(predictedAddress);

    if (code !== '0x') {
      return res.json({
        success: true,
        address: predictedAddress,
        alreadyExists: true
      });
    }

    // Create account (backend pays gas)
    const tx = await factory.createAccount(ownerAddress, 0);
    await tx.wait();

    res.json({
      success: true,
      address: predictedAddress,
      alreadyExists: false
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get account balance and nonce
app.get('/api/account/:address', async (req, res) => {
  const { address } = req.params;

  try {
    const balance = await provider.getBalance(address);
    const accountContract = new ethers.Contract(
      address,
      ['function getNonce() view returns (uint256)'],
      provider
    );
    const nonce = await accountContract.getNonce();

    res.json({
      address,
      balance: ethers.formatEther(balance),
      nonce: nonce.toString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000);
```

---

## Common Use Cases

### Use Case 1: Simple dApp (Frontend Only) ✅ Easiest

**Architecture:**
```
User → Frontend (ethers.js) → Smart Contracts (Lisk Sepolia)
```

**What you need:**
- Frontend (React/Vue/etc)
- ethers.js or viem
- User's MetaMask or wallet

**User flow:**
1. User connects wallet (MetaMask)
2. Frontend creates smart account for user (one-time)
3. User signs transactions with their EOA
4. Frontend submits to smart contract directly
5. User pays gas fees

**Perfect for:**
- Simple dApps
- Users who have ETH for gas
- MVP/Prototype

---

### Use Case 2: dApp with Backend (Gas Sponsorship) 💰

**Architecture:**
```
User → Frontend → Backend (Bundler/Paymaster) → Smart Contracts
```

**What you need:**
- Frontend
- Backend API (Node.js/Python)
- Bundler service
- Backend wallet with ETH (to sponsor gas)

**User flow:**
1. User connects wallet
2. Backend creates smart account (backend pays gas)
3. User signs UserOperations (off-chain)
4. Backend submits to EntryPoint (backend pays gas)
5. User doesn't pay gas! 🎉

**Perfect for:**
- Better UX (gasless transactions)
- Onboarding new users
- Enterprise applications

---

### Use Case 3: Full Account Abstraction Platform 🚀

**Architecture:**
```
User → Frontend → Backend (APIs + Bundler + Paymaster + Analytics) → Smart Contracts
```

**What you need:**
- Frontend
- Backend with multiple services
- Database for user data
- Monitoring and analytics

**Features:**
- Account recovery (social recovery, guardians)
- Transaction batching
- Scheduled transactions
- Multi-sig support
- Gas optimization
- User analytics

**Perfect for:**
- Production applications
- Wallet services
- DeFi platforms

---

## Quick Start Guide

### For Frontend Developers (Start Here!)

1. **Install dependencies:**
```bash
npm install ethers
```

2. **Create a simple page:**
```typescript
import { ethers } from 'ethers';

const FACTORY = '0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F';
const RPC = 'https://rpc.sepolia-api.lisk.com';

async function main() {
  // Connect to Lisk Sepolia
  const provider = new ethers.JsonRpcProvider(RPC);

  // Your user's wallet (from MetaMask or similar)
  const signer = new ethers.Wallet('USER_PRIVATE_KEY', provider);

  // Factory contract
  const factory = new ethers.Contract(
    FACTORY,
    ['function createAccount(address,uint256)', 'function getAddress(address,uint256) view returns (address)'],
    signer
  );

  // Get user's address
  const userAddress = await signer.getAddress();

  // Get smart account address
  const smartAccount = await factory.getAddress(userAddress, 0);
  console.log('Smart Account:', smartAccount);

  // Create it if needed
  const tx = await factory.createAccount(userAddress, 0);
  await tx.wait();
  console.log('Account created!');
}
```

3. **Try it now:**
```bash
# Use cast to test (no frontend needed)
cast call 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F \
  "getAddress(address,uint256)" \
  YOUR_ADDRESS \
  0 \
  --rpc-url https://rpc.sepolia-api.lisk.com
```

---

### For Backend Developers

1. **Set up Express API:**
```bash
npm install express ethers dotenv
```

2. **Create API endpoints** (see backend examples above)

3. **Deploy:**
```bash
# Set environment variables
export BACKEND_PRIVATE_KEY=your_key
export RPC_URL=https://rpc.sepolia-api.lisk.com

# Run
node backend/api.js
```

---

## Summary

| Component | Required? | What it does | Who uses it |
|-----------|-----------|--------------|-------------|
| Smart Contracts | ✅ Yes | Store assets, execute transactions | Everyone |
| Frontend | ✅ Yes | User interface, sign transactions | End users |
| Backend/Bundler | ⚠️ Optional | Gas sponsorship, bundling, APIs | Advanced use cases |

**Recommended approach:**
1. **Start with Frontend only** - Direct interaction with smart contracts
2. **Add Backend later** - When you need gas sponsorship or advanced features
3. **Scale gradually** - Add more backend services as needed

**Your contracts are already deployed and verified! You can start building your frontend today.** 🎉
