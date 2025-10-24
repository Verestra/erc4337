#!/bin/bash

echo "🚀 Starting Gasless ERC-4337 Backend..."
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo ""
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT: Edit .env and add your BACKEND_PRIVATE_KEY"
    echo ""
    echo "Run: nano .env"
    echo "Or: echo 'BACKEND_PRIVATE_KEY=your_key_here' > .env"
    echo ""
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Start the server
echo "✅ Starting server on port 3131..."
echo ""
npm start
