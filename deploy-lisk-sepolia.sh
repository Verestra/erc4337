#!/bin/bash

# Deploy to Lisk Sepolia Testnet
# Make sure to set PRIVATE_KEY in .env file

echo "🚀 Deploying to Lisk Sepolia..."
echo ""

# Load environment variables
source .env

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env file"
    exit 1
fi

# Deploy
forge script script/DeploySimpleAccountFactory.s.sol:DeploySimpleAccountFactory \
    --rpc-url https://rpc.sepolia-api.lisk.com \
    --broadcast \
    --verify \
    --chain-id 4202 \
    -vvvv

echo ""
echo "✅ Deployment complete!"
echo "📝 Check deployment details in broadcast/ folder"
echo "🔍 Verify on: https://sepolia-blockscout.lisk.com"
