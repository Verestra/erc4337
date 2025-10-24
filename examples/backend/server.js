import express from 'express';
import cors from 'cors';
import { ethers } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Contract addresses on Lisk Sepolia
const FACTORY_ADDRESS = '0xbCa99c484Ca08B7c5FDaC58e2505a08595955B8F';
const RPC_URL = 'https://rpc.sepolia-api.lisk.com';

// Setup provider and signer
const provider = new ethers.JsonRpcProvider(RPC_URL);
const backendWallet = new ethers.Wallet(process.env.BACKEND_PRIVATE_KEY || '', provider);

const FACTORY_ABI = [
  'function createAccount(address owner, uint256 salt) returns (address)',
  'function getAddress(address owner, uint256 salt) view returns (address)',
  'function accountImplementation() view returns (address)'
];

const ACCOUNT_ABI = [
  'function execute(address dest, uint256 value, bytes calldata func)',
  'function owner() view returns (address)',
  'function entryPoint() view returns (address)',
  'function getNonce() view returns (uint256)',
  'function getDeposit() view returns (uint256)'
];

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'ERC-4337 Backend API' });
});

// Get factory info
app.get('/api/factory', async (req, res) => {
  try {
    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);
    const implementation = await factory.accountImplementation();

    res.json({
      success: true,
      factory: FACTORY_ADDRESS,
      implementation,
      network: 'Lisk Sepolia',
      chainId: 4202
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get smart account address (counterfactual)
app.get('/api/account/:owner/:salt', async (req, res) => {
  try {
    const { owner, salt } = req.params;

    if (!ethers.isAddress(owner)) {
      return res.status(400).json({ success: false, error: 'Invalid owner address' });
    }

    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);
    const accountAddress = await factory.getAddress(owner, salt);

    // Check if deployed
    const code = await provider.getCode(accountAddress);
    const isDeployed = code !== '0x';

    let accountInfo = null;
    if (isDeployed) {
      const account = new ethers.Contract(accountAddress, ACCOUNT_ABI, provider);
      const balance = await provider.getBalance(accountAddress);
      const nonce = await account.getNonce();
      const accountOwner = await account.owner();

      accountInfo = {
        address: accountAddress,
        owner: accountOwner,
        balance: ethers.formatEther(balance),
        nonce: nonce.toString(),
        isDeployed: true
      };
    }

    res.json({
      success: true,
      accountAddress,
      isDeployed,
      accountInfo,
      explorerUrl: `https://sepolia-blockscout.lisk.com/address/${accountAddress}`
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create smart account (gas sponsored by backend)
app.post('/api/account/create', async (req, res) => {
  try {
    const { owner, salt = 0 } = req.body;

    if (!owner || !ethers.isAddress(owner)) {
      return res.status(400).json({ success: false, error: 'Invalid owner address' });
    }

    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, backendWallet);

    // Check if already exists
    const accountAddress = await factory.getAddress(owner, salt);
    const code = await provider.getCode(accountAddress);

    if (code !== '0x') {
      return res.json({
        success: true,
        accountAddress,
        alreadyExists: true,
        message: 'Account already exists',
        explorerUrl: `https://sepolia-blockscout.lisk.com/address/${accountAddress}`
      });
    }

    // Create account (backend pays gas)
    console.log(`Creating account for ${owner} with salt ${salt}...`);
    const tx = await factory.createAccount(owner, salt);
    console.log(`Transaction sent: ${tx.hash}`);

    const receipt = await tx.wait();
    console.log(`Account created in block ${receipt.blockNumber}`);

    res.json({
      success: true,
      accountAddress,
      alreadyExists: false,
      transactionHash: receipt.hash,
      blockNumber: receipt.blockNumber,
      gasUsed: receipt.gasUsed.toString(),
      explorerUrl: `https://sepolia-blockscout.lisk.com/address/${accountAddress}`,
      txUrl: `https://sepolia-blockscout.lisk.com/tx/${receipt.hash}`
    });
  } catch (error) {
    console.error('Error creating account:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get account details
app.get('/api/account/:address', async (req, res) => {
  try {
    const { address } = req.params;

    if (!ethers.isAddress(address)) {
      return res.status(400).json({ success: false, error: 'Invalid address' });
    }

    // Check if account exists
    const code = await provider.getCode(address);
    if (code === '0x') {
      return res.status(404).json({
        success: false,
        error: 'Account not found or not deployed'
      });
    }

    const account = new ethers.Contract(address, ACCOUNT_ABI, provider);
    const balance = await provider.getBalance(address);
    const owner = await account.owner();
    const nonce = await account.getNonce();
    const entryPoint = await account.entryPoint();
    const deposit = await account.getDeposit();

    res.json({
      success: true,
      account: {
        address,
        owner,
        balance: ethers.formatEther(balance),
        balanceWei: balance.toString(),
        nonce: nonce.toString(),
        entryPoint,
        deposit: ethers.formatEther(deposit),
        depositWei: deposit.toString()
      },
      explorerUrl: `https://sepolia-blockscout.lisk.com/address/${address}`
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get multiple accounts for a user
app.get('/api/accounts/:owner', async (req, res) => {
  try {
    const { owner } = req.params;
    const limit = parseInt(req.query.limit) || 5;

    if (!ethers.isAddress(owner)) {
      return res.status(400).json({ success: false, error: 'Invalid owner address' });
    }

    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);
    const accounts = [];

    // Check first N salts
    for (let salt = 0; salt < limit; salt++) {
      const accountAddress = await factory.getAddress(owner, salt);
      const code = await provider.getCode(accountAddress);

      if (code !== '0x') {
        const balance = await provider.getBalance(accountAddress);
        accounts.push({
          address: accountAddress,
          salt,
          balance: ethers.formatEther(balance),
          explorerUrl: `https://sepolia-blockscout.lisk.com/address/${accountAddress}`
        });
      }
    }

    res.json({
      success: true,
      owner,
      accounts,
      totalFound: accounts.length
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Execute gasless transaction (backend pays gas)
app.post('/api/transaction/execute', async (req, res) => {
  try {
    const { accountAddress, recipient, amount, data = '0x' } = req.body;

    // Validate inputs
    if (!accountAddress || !ethers.isAddress(accountAddress)) {
      return res.status(400).json({ success: false, error: 'Invalid account address' });
    }
    if (!recipient || !ethers.isAddress(recipient)) {
      return res.status(400).json({ success: false, error: 'Invalid recipient address' });
    }
    if (!amount || parseFloat(amount) <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid amount' });
    }

    // Check if account exists
    const code = await provider.getCode(accountAddress);
    if (code === '0x') {
      return res.status(404).json({
        success: false,
        error: 'Smart account not found. Create it first.'
      });
    }

    const account = new ethers.Contract(accountAddress, ACCOUNT_ABI, backendWallet);

    console.log(`Executing transaction from ${accountAddress} to ${recipient}...`);
    console.log(`Amount: ${amount} ETH`);

    // Execute transaction (backend pays gas)
    const tx = await account.execute(
      recipient,
      ethers.parseEther(amount),
      data
    );

    console.log(`Transaction sent: ${tx.hash}`);

    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block ${receipt.blockNumber}`);

    res.json({
      success: true,
      message: 'Transaction executed successfully (gas paid by backend)',
      transactionHash: receipt.hash,
      blockNumber: receipt.blockNumber,
      gasUsed: receipt.gasUsed.toString(),
      from: accountAddress,
      to: recipient,
      amount: amount,
      txUrl: `https://sepolia-blockscout.lisk.com/tx/${receipt.hash}`
    });
  } catch (error) {
    console.error('Error executing transaction:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get backend wallet info
app.get('/api/backend/info', async (req, res) => {
  try {
    const address = await backendWallet.getAddress();
    const balance = await provider.getBalance(address);

    res.json({
      success: true,
      backend: {
        address,
        balance: ethers.formatEther(balance),
        balanceWei: balance.toString(),
        network: 'Lisk Sepolia',
        chainId: 4202
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3131;

app.listen(PORT, () => {
  console.log(`
🚀 ERC-4337 Backend API running on port ${PORT}

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
🏭 Factory: ${FACTORY_ADDRESS}
💼 Backend Wallet: ${backendWallet.address}

💡 Gasless Features Enabled:
  ✅ Account creation (backend pays gas)
  ✅ Transaction execution (backend pays gas)
  `);
});
