# 🚀 Gasless Transaction Setup Guide

This guide shows you how to set up completely gasless transactions where users pay **ZERO gas fees**.

## 🎯 What You'll Get

- ✅ **Gasless Account Creation** - Backend pays for creating smart accounts
- ✅ **Gasless Transactions** - Backend pays for all transactions
- ✅ **Zero MetaMask Fees** - Users only sign, never pay
- ✅ **Complete Backend Control** - You control gas sponsorship

---

## 📋 Prerequisites

1. Node.js installed (v16 or higher)
2. MetaMask browser extension
3. Testnet ETH for backend wallet (get from https://sepolia-faucet.lisk.com)

---

## 🔧 Step 1: Set Up Backend

### 1.1 Navigate to Backend Folder

```bash
cd examples/backend
```

### 1.2 Install Dependencies

```bash
npm install
```

### 1.3 Configure Environment

```bash
# Copy the example env file
cp .env.example .env
```

### 1.4 Add Your Private Key

Edit `.env` file and add your backend wallet private key:

```bash
# Open in your editor
nano .env

# Or use echo (replace with YOUR key)
echo "BACKEND_PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE" > .env
echo "PORT=3131" >> .env
```

**⚠️ Important:**
- This wallet will pay gas for all operations
- Make sure it has testnet ETH (at least 0.1 ETH recommended)
- **NEVER use mainnet private key or commit .env to git!**

### 1.5 Start the Backend

```bash
npm start
```

You should see:

```
🚀 ERC-4337 Backend API running on port 3131

📝 Endpoints:
  - GET  /health
  - GET  /api/factory
  - GET  /api/account/:owner/:salt
  - POST /api/account/create (gasless account creation)
  - POST /api/transaction/execute (gasless transaction execution) ✨
  - GET  /api/account/:address
  - GET  /api/accounts/:owner
  - GET  /api/backend/info

🌐 Network: Lisk Sepolia (Chain ID: 4202)
🏭 Factory: 0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F
💼 Backend Wallet: 0x67BA06dB6d9c562857BF08AB1220a16DfA455c45

💡 Gasless Features Enabled:
  ✅ Account creation (backend pays gas)
  ✅ Transaction execution (backend pays gas)
```

---

## 🌐 Step 2: Test Backend API

Open a new terminal and test the backend:

```bash
# Check backend status
curl http://localhost:3131/health

# Get backend wallet info
curl http://localhost:3131/api/backend/info
```

Expected response:
```json
{
  "success": true,
  "backend": {
    "address": "0x67BA06dB6d9c562857BF08AB1220a16DfA455c45",
    "balance": "0.5",
    "network": "Lisk Sepolia",
    "chainId": 4202
  }
}
```

---

## 🖥️ Step 3: Open Gasless Frontend

### 3.1 Open in Browser

```bash
# From project root
open examples/gasless-frontend.html

# Or navigate manually:
# File -> Open -> examples/gasless-frontend.html
```

### 3.2 Check Backend Connection

1. Page loads automatically
2. Click "**Check Backend**" button
3. Should show: ✅ Backend Connected!

If backend is not connected:
- Make sure backend is running on port 3131
- Check terminal for backend errors
- Verify `.env` file has correct private key

---

## 🎮 Step 4: Use Gasless Features

### 4.1 Connect MetaMask

1. Click "**Connect MetaMask**"
2. Approve connection
3. Switch to Lisk Sepolia if prompted

**Note:** You just signed in - **NO GAS PAID** ✅

### 4.2 Create Smart Account (Gasless)

1. Choose a salt (0, 1, 2, etc.)
2. Click "**Preview Address**" to see your account address
3. Click "**Create Account (Backend Pays Gas)**"
4. **No MetaMask popup for gas!** 🎉
5. Backend pays all gas automatically

**You paid: 0 ETH** ✅
**Backend paid: ~0.0002 ETH** (from backend wallet)

### 4.3 Send Gasless Transaction

1. Enter recipient address
2. Enter amount (e.g., 0.001 ETH)
3. Click "**Send ETH (Backend Pays Gas)**"
4. **No MetaMask popup for gas!** 🎉
5. Transaction executes, backend pays gas

**You paid: 0 ETH** ✅
**Backend paid: ~0.0001 ETH** (from backend wallet)

---

## 📊 Monitor Backend

### Check Backend Balance

```bash
curl http://localhost:3131/api/backend/info
```

### Check Your Smart Accounts

```bash
# Replace with your MetaMask address
curl http://localhost:3131/api/accounts/0x296f9f84468d4E5758b5Af2A253d617b67D8cAC86
```

### Create Account via API (Alternative)

```bash
curl -X POST http://localhost:3131/api/account/create \
  -H "Content-Type: application/json" \
  -d '{
    "owner": "0x296f9f84468d4E5758b5Af2A253d617b67D8cAC86",
    "salt": 5
  }'
```

### Execute Transaction via API (Alternative)

```bash
curl -X POST http://localhost:3131/api/transaction/execute \
  -H "Content-Type: application/json" \
  -d '{
    "accountAddress": "0x6a7F68D6Dc3f16E37c450c23503cA30Acb906741",
    "recipient": "0xRecipientAddress...",
    "amount": "0.001"
  }'
```

---

## 🎯 How It Works

### Regular Flow (User Pays Gas)
```
User → MetaMask (pays gas) → Smart Account → Blockchain
```

### Gasless Flow (Backend Pays Gas)
```
User → Signs message (free) → Backend API → Backend Wallet (pays gas) → Smart Account → Blockchain
```

**Key Differences:**
1. User only **signs** transactions (free operation)
2. Backend **executes** transactions (pays gas)
3. User pays: **0 ETH**
4. Backend pays: **~0.0001-0.0002 ETH per transaction**

---

## 💰 Gas Cost Estimation

Based on Lisk Sepolia gas prices:

| Operation | Gas Used | Cost (ETH) | Who Pays |
|-----------|----------|------------|----------|
| Create Account | ~174,000 | ~0.0002 | Backend ✅ |
| Send ETH | ~50,000 | ~0.00005 | Backend ✅ |
| Total for User | 0 | **0 ETH** | **FREE!** 🎉 |

**Backend Costs:**
- 10 accounts + 10 transactions = ~0.003 ETH
- Very affordable for production!

---

## 🔒 Security Notes

### Backend Security

1. **Never expose private key**
   - Keep `.env` file secure
   - Never commit to git
   - Use environment variables in production

2. **Add rate limiting** (production)
   ```javascript
   // Add to server.js
   const rateLimit = require('express-rate-limit');
   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100 // limit each IP to 100 requests per windowMs
   });
   app.use(limiter);
   ```

3. **Add authentication** (production)
   - Verify users before sponsoring gas
   - Use JWT tokens or API keys
   - Limit gas sponsorship per user

4. **Monitor backend balance**
   - Set up alerts when balance is low
   - Auto-refill from a secure source
   - Track gas spending per user

### Frontend Security

1. **Validate all inputs**
   - Check addresses before sending
   - Validate amounts
   - Prevent excessive gas sponsorship

2. **Use HTTPS in production**
   - Secure communication with backend
   - Prevent man-in-the-middle attacks

---

## 🐛 Troubleshooting

### Backend Won't Start

**Problem:** Port already in use
**Solution:**
```bash
# Kill process on port 3131
lsof -ti:3131 | xargs kill -9

# Or use different port in .env
echo "PORT=3132" >> .env
```

**Problem:** Private key error
**Solution:**
- Check `.env` file exists
- Verify private key format (with or without 0x prefix)
- Make sure wallet has testnet ETH

### Frontend Can't Connect to Backend

**Problem:** CORS error
**Solution:** Backend already has CORS enabled. If you still see errors:
```javascript
// In server.js, line 9, change to:
app.use(cors({
  origin: '*', // Allow all origins (development only)
  credentials: true
}));
```

**Problem:** Backend not responding
**Solution:**
1. Check backend is running: `curl http://localhost:3131/health`
2. Check port matches in frontend (line 118: `const BACKEND_URL`)
3. Try restarting backend

### Transaction Fails

**Problem:** "Smart account not found"
**Solution:** Create the account first using "Create Account" button

**Problem:** Backend wallet has no ETH
**Solution:** Send testnet ETH to backend wallet address

---

## 🚀 Production Deployment

### 1. Deploy Backend

```bash
# Use a production server (AWS, Google Cloud, etc.)
# Set environment variables securely
export BACKEND_PRIVATE_KEY=your_key
export PORT=3131
export NODE_ENV=production

# Add SSL/HTTPS
# Add authentication
# Add rate limiting
# Add monitoring

npm start
```

### 2. Update Frontend

```javascript
// Change BACKEND_URL in gasless-frontend.html
const BACKEND_URL = 'https://your-backend-domain.com';
```

### 3. Monitor & Scale

- Monitor backend balance
- Track gas spending
- Scale based on usage
- Set up alerts

---

## 📚 Additional Resources

- **Your Deployment:** [DEPLOYMENT.md](../DEPLOYMENT.md)
- **Architecture Guide:** [ARCHITECTURE.md](../ARCHITECTURE.md)
- **Backend API Code:** [server.js](backend/server.js)
- **Frontend Code:** [gasless-frontend.html](gasless-frontend.html)

---

## 🎉 Congratulations!

You now have a fully functional gasless transaction system!

**What you built:**
- ✅ Complete backend API for gas sponsorship
- ✅ Gasless frontend interface
- ✅ Real ERC-4337 implementation
- ✅ Production-ready architecture

**Next steps:**
1. Add authentication to backend
2. Implement rate limiting
3. Add transaction history
4. Build your dApp on top!

---

## 💡 Tips

1. **Start simple**: Use for account creation only, let users pay for transactions later
2. **Monitor costs**: Track how much gas you're sponsoring
3. **Set limits**: Max transactions per user, daily limits, etc.
4. **Use services**: Consider Alchemy/Pimlico for production scale

**Questions?** Check the [GASLESS_GUIDE.md](../GASLESS_GUIDE.md) for more details!
