# ERC-4337 Examples

This folder contains ready-to-use examples for interacting with your deployed ERC-4337 smart accounts.

## 📁 Examples

### 1. Simple Frontend (HTML + JavaScript)

**File:** `simple-frontend.html`

A standalone HTML page that demonstrates:
- Connecting to MetaMask
- Creating smart accounts
- Checking account balances
- Sending ETH from smart accounts

**How to use:**
```bash
# Just open in your browser!
open simple-frontend.html

# Or use a simple server:
python3 -m http.server 8000
# Then visit: http://localhost:8000/simple-frontend.html
```

**Features:**
- ✅ No build step required
- ✅ Uses ethers.js from CDN
- ✅ MetaMask integration
- ✅ Interactive UI

---

### 2. Backend API (Node.js + Express)

**Folder:** `backend/`

A REST API server that provides:
- Gas-sponsored account creation
- Account information queries
- Multi-account management
- Backend wallet management

**Setup:**
```bash
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env and add your backend wallet private key
nano .env

# Start the server
npm start
```

**API Endpoints:**

```bash
# Health check
GET /health

# Get factory info
GET /api/factory

# Get counterfactual address
GET /api/account/:owner/:salt

# Create account (gas sponsored by backend)
POST /api/account/create
Body: { "owner": "0x...", "salt": 0 }

# Get account details
GET /api/account/:address

# Get all accounts for an owner
GET /api/accounts/:owner?limit=5

# Get backend wallet info
GET /api/backend/info
```

**Example API calls:**

```bash
# Get factory information
curl http://localhost:3000/api/factory

# Get smart account address for owner
curl http://localhost:3000/api/account/0x67BA06dB6d9c562857BF08AB1220a16DfA455c45/0

# Create account (backend pays gas!)
curl -X POST http://localhost:3000/api/account/create \
  -H "Content-Type: application/json" \
  -d '{"owner": "0x67BA06dB6d9c562857BF08AB1220a16DfA455c45", "salt": 0}'

# Get account details
curl http://localhost:3000/api/account/0x34e187b50054861561927ac24f6995f54ec931c8

# Get all accounts for an owner
curl http://localhost:3000/api/accounts/0x67BA06dB6d9c562857BF08AB1220a16DfA455c45

# Check backend wallet balance
curl http://localhost:3000/api/backend/info
```

**Features:**
- ✅ Gas sponsorship (backend pays gas)
- ✅ RESTful API
- ✅ Account management
- ✅ CORS enabled for frontend integration

---

## 🔗 Integration Patterns

### Pattern 1: Frontend Only (No Backend)

```
User → MetaMask → Frontend → Smart Contracts
```

**Use when:**
- Simple dApps
- Users have ETH for gas
- MVP/Prototype

**Use:** `simple-frontend.html`

---

### Pattern 2: Frontend + Backend API

```
User → Frontend → Backend API → Smart Contracts
```

**Use when:**
- You want to sponsor gas fees
- Better UX (gasless transactions)
- Need account management APIs

**Use:** `simple-frontend.html` + `backend/server.js`

**Frontend modification to use backend:**

```javascript
// Instead of creating account directly:
// const tx = await factory.createAccount(userAddress, 0);

// Use backend API:
const response = await fetch('http://localhost:3000/api/account/create', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ owner: userAddress, salt: 0 })
});

const data = await response.json();
console.log('Account created:', data.accountAddress);
```

---

## 🎯 Quick Start Guide

### Option 1: Test Frontend Only (Fastest)

1. Make sure you have MetaMask installed
2. Add Lisk Sepolia network to MetaMask:
   - Chain ID: 4202
   - RPC URL: https://rpc.sepolia-api.lisk.com
3. Get testnet ETH from: https://sepolia-faucet.lisk.com
4. Open `simple-frontend.html` in your browser
5. Connect MetaMask and start creating accounts!

### Option 2: Test Backend API

1. Setup backend:
```bash
cd backend
npm install
cp .env.example .env
# Add your private key to .env
npm start
```

2. Test API:
```bash
# Create an account
curl -X POST http://localhost:3000/api/account/create \
  -H "Content-Type: application/json" \
  -d '{"owner": "0xYOUR_ADDRESS", "salt": 0}'
```

3. Integrate with frontend by updating the HTML file to call your API

---

## 📚 More Examples

For production-ready examples with:
- React/Next.js integration
- TypeScript
- Paymaster support
- Advanced features

See: [ARCHITECTURE.md](../ARCHITECTURE.md)

---

## 🔒 Security Notes

1. **Frontend:**
   - Never hardcode private keys
   - Always use MetaMask or similar wallet
   - Validate user inputs

2. **Backend:**
   - Keep `.env` file secure
   - Never commit private keys to git
   - Use environment variables in production
   - Implement rate limiting for production
   - Add authentication/authorization

3. **Both:**
   - Test on testnet first
   - Verify all contract addresses
   - Monitor gas costs

---

## 💡 Tips

1. **Testing with cast:**
```bash
# Quick test without frontend
cast call 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F \
  "getAddress(address,uint256)" \
  0xYOUR_ADDRESS \
  0 \
  --rpc-url https://rpc.sepolia-api.lisk.com
```

2. **Multiple accounts:**
   - Use different salt values (0, 1, 2, ...) to create multiple accounts for the same owner
   - Each salt creates a unique deterministic address

3. **Gas optimization:**
   - Accounts are deployed once, then reused
   - Use `getAddress()` to check if account exists before creating

---

## 🐛 Troubleshooting

**Frontend not connecting:**
- Check MetaMask is installed
- Verify you're on Lisk Sepolia network (Chain ID: 4202)
- Check browser console for errors

**Backend API errors:**
- Verify private key is set in `.env`
- Check backend wallet has ETH: `curl http://localhost:3000/api/backend/info`
- Check contract addresses match deployed contracts

**Transactions failing:**
- Ensure account has sufficient ETH
- Check gas prices on network
- Verify contract addresses are correct

---

## 📞 Support

- **Contracts:** See [DEPLOYMENT.md](../DEPLOYMENT.md)
- **Architecture:** See [ARCHITECTURE.md](../ARCHITECTURE.md)
- **Lisk Docs:** https://docs.lisk.com
- **Explorer:** https://sepolia-blockscout.lisk.com

---

## 🎉 You're Ready!

Your ERC-4337 smart contracts are deployed and verified on Lisk Sepolia. Start with the simple frontend, then add backend features as needed!

**Deployed Contracts:**
- Factory: `0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F` ✅
- Implementation: `0x826224A88d942Cc4E0341E18A2831EF7fFeA1500` ✅
- EntryPoint: `0x0000000071727De22E5E9d8BAf0edAc6f37da032` ✅
