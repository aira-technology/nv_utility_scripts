#!/bin/bash

# Repository Tag Scanner API Startup Script

echo "🚀 Starting Repository Tag Scanner API..."
echo "========================================"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/upgrade dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  Warning: GitHub CLI (gh) is not installed."
    echo "   Install with: brew install gh"
    echo "   Then authenticate with: gh auth login"
else
    echo "✅ GitHub CLI found"
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo "⚠️  Warning: GitHub CLI is not authenticated."
        echo "   Please run: gh auth login"
    else
        echo "✅ GitHub CLI authenticated"
    fi
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed."
    exit 1
else
    echo "✅ Git found"
fi

# Check if jq is installed (optional but recommended)
if ! command -v jq &> /dev/null; then
    echo "⚠️  Info: jq is not installed (optional)."
    echo "   Install with: brew install jq"
else
    echo "✅ jq found"
fi

echo
echo "🌐 Starting API server..."
echo "📍 API will be available at: http://localhost:8000"
echo "📚 API documentation at: http://localhost:8000/docs"
echo "📖 Alternative docs at: http://localhost:8000/redoc"
echo
echo "Press Ctrl+C to stop the server"
echo "========================================"

# Start the API server
python app.py

