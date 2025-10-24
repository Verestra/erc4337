# ⚡ Quick Start: Gasless Transactions

Get your gasless ERC-4337 system running in 3 minutes!

---

## 🏃 Quick Setup (3 Steps)

### 1️⃣ Start Backend (Port 3131)

```bash
cd examples/backend

# First time: Install dependencies
npm install

# Setup environment
echo "BACKEND_PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE" > .env
echo "PORT=3131" >> .env
# ⚠️ Replace YOUR_PRIVATE_KEY_HERE with your actual private key!

# Start server
npm start
```

**Expected output:**
```
🚀 ERC-4337 Backend API running on port 3131
💼 Backend Wallet: 0x67BA06dB6d9c562857BF08AB1220a16DfA455c45
💡 Gasless Features Enabled:
  ✅ Account creation (backend pays gas)
  ✅ Transaction execution (backend pays gas)
```

---

### 2️⃣ Test Backend

Open new terminal:

```bash
# Check backend is running
curl http://localhost:3131/health

# Check backend wallet balance
curl http://localhost:3131/api/backend/info
```

---

### 3️⃣ Open Frontend

```bash
# From project root
open examples/gasless-frontend.html
```

**Or** double-click: `examples/gasless-frontend.html`

---

## 🎮 Usage

### In the Browser:

1. **Click "Check Backend"** → Should show ✅ Connected
2. **Click "Connect MetaMask"** → Connect your wallet
3. **Click "Create Account (Backend Pays Gas)"** → **No gas popup!** 🎉
4. **Send ETH (Backend Pays Gas)** → **No gas popup!** 🎉

### You Paid: **0 ETH** ✅

---

## 🧪 Test via Command Line

```bash
# Create account (gasless)
curl -X POST http://localhost:3131/api/account/create \
  -H "Content-Type: application/json" \
  -d '{"owner": "0xYOUR_ADDRESS", "salt": 0}'

# Send transaction (gasless)
curl -X POST http://localhost:3131/api/transaction/execute \
  -H "Content-Type: application/json" \
  -d '{
    "accountAddress": "0xYOUR_SMART_ACCOUNT",
    "recipient": "0xRECIPIENT",
    "amount": "0.001"
  }'
```

---

## 📁 File Structure

```
examples/
├── gasless-frontend.html       ← Open this in browser
├── backend/
│   ├── server.js              ← Backend API (port 3131)
│   ├── .env                   ← Your private key HERE
│   ├── package.json
│   └── start-gasless.sh       ← Quick start script
└── GASLESS_SETUP.md           ← Detailed guide
```

---

## 🔥 Quick Commands

```bash
# Start backend
cd examples/backend && npm start

# Check backend
curl http://localhost:3131/health

# Open frontend
open examples/gasless-frontend.html

# Check backend balance
curl http://localhost:3131/api/backend/info
```

---

## ⚠️ Troubleshooting

### Backend won't start?

```bash
# Make sure you have .env file
cd examples/backend
cat .env

# Should show:
# BACKEND_PRIVATE_KEY=your_key_here
# PORT=3131
```

### Frontend can't connect?

1. Check backend is running: `curl http://localhost:3131/health`
2. Check port 3131 is correct
3. Look at browser console (F12)

### Backend has no ETH?

Get testnet ETH:
- Faucet: https://sepolia-faucet.lisk.com
- Send to your backend wallet address

---

## 📊 What Just Happened?

| Action | User Pays | Backend Pays | Total Cost |
|--------|-----------|--------------|------------|
| Connect MetaMask | 0 ETH | 0 ETH | **FREE** ✅ |
| Create Account | 0 ETH | ~0.0002 ETH | **FREE for user** ✅ |
| Send Transaction | 0 ETH | ~0.00005 ETH | **FREE for user** ✅ |
| **Total** | **0 ETH** | ~0.00025 ETH | **100% Gasless!** 🎉 |

---

## 🎯 API Endpoints (localhost:3131)

```bash
GET  /health                      # Check server status
GET  /api/backend/info            # Backend wallet info
POST /api/account/create          # Create account (gasless)
POST /api/transaction/execute     # Send transaction (gasless)
GET  /api/account/:address        # Get account details
GET  /api/accounts/:owner         # List user's accounts
```

---

## 📚 Full Documentation

- **Detailed Setup:** [examples/GASLESS_SETUP.md](examples/GASLESS_SETUP.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Gasless Guide:** [GASLESS_GUIDE.md](GASLESS_GUIDE.md)
- **Deployment:** [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 🎉 Success Checklist

- [ ] Backend running on port 3131
- [ ] Backend wallet has testnet ETH
- [ ] `curl http://localhost:3131/health` returns OK
- [ ] Frontend opens in browser
- [ ] Frontend shows "Backend Connected"
- [ ] MetaMask connected
- [ ] Created smart account WITHOUT paying gas
- [ ] Sent transaction WITHOUT paying gas

**All checked?** You're running a complete gasless ERC-4337 system! 🚀

---

## 💡 Next Steps

1. ✅ Try creating multiple accounts (different salts)
2. ✅ Send transactions between accounts
3. ✅ Monitor backend gas spending
4. ✅ Add authentication (for production)
5. ✅ Deploy to a real server

**Questions?** See [examples/GASLESS_SETUP.md](examples/GASLESS_SETUP.md) for detailed help!
