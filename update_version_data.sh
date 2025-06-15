#!/bin/bash

# Automated Version Data Update Script
# This script can be run via cron or CI/CD to automatically update version tag data
# and commit it to a Git repository for UI consumption

set -e  # Exit on any error

# Configuration
ORG_NAME=${ORG_NAME:-"aira-technology"}
TAG_VERSION=${TAG_VERSION:-"0.75.5"}
API_URL=${API_URL:-"http://localhost:8000"}
DATA_REPO=${DATA_REPO:-"git@github.com:aira-technology/version-data.git"}
DATA_BRANCH=${DATA_BRANCH:-"main"}
DATA_FILE=${DATA_FILE:-"version_tags.json"}
DEPLOYMENT_CONFIG=${DEPLOYMENT_CONFIG:-"config/deployment_config.json"}
GIT_COMMIT_MESSAGE=${GIT_COMMIT_MESSAGE:-"Auto-update version tag data"}

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/version-data-update-$$"
DATA_DIR="$TEMP_DIR/version-data"

echo "🚀 Starting automated version data update..."
echo "========================================"
echo "Organization: $ORG_NAME"
echo "Tag Version: $TAG_VERSION"
echo "API URL: $API_URL"
echo "Data Repository: $DATA_REPO"
echo "Data File: $DATA_FILE"
echo "========================================"

# Function to cleanup on exit
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Check if API is available
echo "🔍 Checking API availability..."
if ! curl -s --max-time 10 "$API_URL/api/v1/health" > /dev/null; then
    echo "❌ API is not available at $API_URL"
    echo "Starting local API server..."
    
    # Try to start the API server in background
    cd "$SCRIPT_DIR"
    if [ -f "start_api.sh" ]; then
        ./start_api.sh &
        API_PID=$!
        
        # Wait for API to be ready
        echo "Waiting for API to be ready..."
        for i in {1..30}; do
            if curl -s --max-time 5 "$API_URL/api/v1/health" > /dev/null; then
                echo "✅ API is now available"
                break
            fi
            sleep 2
        done
        
        # Kill API server when script exits
        trap 'kill $API_PID 2>/dev/null || true; cleanup' EXIT
    else
        echo "❌ Cannot start API server. Please ensure it's running."
        exit 1
    fi
    cd "$TEMP_DIR"
else
    echo "✅ API is available"
fi

# Clone or update the data repository
echo "📦 Setting up data repository..."
if [ -n "$GITHUB_TOKEN" ]; then
    # Use token-based authentication
    REPO_URL="https://$GITHUB_TOKEN@${DATA_REPO#*@}"
else
    # Use SSH (requires SSH keys to be set up)
    REPO_URL="$DATA_REPO"
fi

if ! git clone "$REPO_URL" version-data 2>/dev/null; then
    echo "⚠️  Could not clone repository. Creating new data directory..."
    mkdir -p version-data
    cd version-data
    git init
    git remote add origin "$REPO_URL" 2>/dev/null || true
else
    cd version-data
    git checkout "$DATA_BRANCH" 2>/dev/null || git checkout -b "$DATA_BRANCH"
    git pull origin "$DATA_BRANCH" 2>/dev/null || true
fi

# Create directory structure
mkdir -p data config schemas

# Copy schema and config files if they exist
if [ -f "$SCRIPT_DIR/schemas/version_tags.json" ]; then
    cp "$SCRIPT_DIR/schemas/version_tags.json" schemas/
fi

if [ -f "$SCRIPT_DIR/$DEPLOYMENT_CONFIG" ]; then
    cp "$SCRIPT_DIR/$DEPLOYMENT_CONFIG" config/
fi

# Fetch and transform data
echo "🔍 Fetching version tag data..."
cd "$SCRIPT_DIR"

# Ensure data transformer has required dependencies
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
else
    echo "⚠️  Virtual environment not found. Using system Python..."
fi

# Run the data transformer
ARGS="--api-url $API_URL --organization $ORG_NAME --tag $TAG_VERSION --output-file $DATA_DIR/data/$DATA_FILE --merge-existing"

if [ -f "$DATA_DIR/config/deployment_config.json" ]; then
    ARGS="$ARGS --deployment-config $DATA_DIR/config/deployment_config.json"
fi

python data_transformer.py $ARGS

if [ $? -ne 0 ]; then
    echo "❌ Data transformation failed"
    exit 1
fi

echo "✅ Data transformation completed"

# Generate additional UI-friendly formats
echo "📊 Generating additional data formats..."
cd "$DATA_DIR"

# Create a summary file for quick UI consumption
python3 << 'EOF'
import json
from datetime import datetime

# Load the main data file
with open('data/version_tags.json', 'r') as f:
    data = json.load(f)

# Create summary for UI
summary = {
    "last_updated": data["metadata"]["last_updated"],
    "organization": data["metadata"]["organization"],
    "total_tags": data["statistics"]["total_unique_tags"],
    "total_repositories": data["statistics"]["total_repositories_with_tags"],
    "most_common_tag": data["statistics"]["most_common_tag"],
    "latest_tag_date": data["statistics"]["latest_tag_date"],
    "tags_overview": {}
}

# Create tags overview
for tag_name, tag_data in data["tags"].items():
    summary["tags_overview"][tag_name] = {
        "repository_count": tag_data["summary"]["total_repositories"],
        "latest_commit_date": tag_data["summary"]["latest_commit_date"],
        "environments": tag_data["summary"]["deployment_environments"],
        "repositories": [repo["repository_name"] for repo in tag_data["repositories"]]
    }

# Save summary
with open('data/summary.json', 'w') as f:
    json.dump(summary, f, indent=2)

# Create environment-specific files
environments = {"production", "staging", "development", "test"}

for env in environments:
    env_data = {
        "environment": env,
        "last_updated": data["metadata"]["last_updated"],
        "repositories": []
    }
    
    for tag_name, tag_data in data["tags"].items():
        for repo in tag_data["repositories"]:
            if repo.get("environment") == env:
                env_data["repositories"].append({
                    "repository_name": repo["repository_name"],
                    "tag_name": tag_name,
                    "commit_short": repo["commit_short"],
                    "deployment_status": repo["deployment_status"],
                    "repository_url": repo["repository_url"],
                    "tag_url": repo["tag_url"]
                })
    
    if env_data["repositories"]:
        with open(f'data/{env}_deployments.json', 'w') as f:
            json.dump(env_data, f, indent=2)

print("Additional data formats generated successfully")
EOF

# Check for changes
echo "🔍 Checking for changes..."
if git diff --quiet; then
    echo "📝 No changes detected in version data"
else
    echo "📝 Changes detected, committing to repository..."
    
    # Configure git if needed
    git config user.email "automation@aira-technology.com" 2>/dev/null || true
    git config user.name "Version Data Bot" 2>/dev/null || true
    
    # Add all changes
    git add .
    
    # Create commit message with details
    COMMIT_MSG="$GIT_COMMIT_MESSAGE

Updated version tag data for $ORG_NAME:
- Tag: $TAG_VERSION
- Scan timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Total repositories scanned: $(jq -r '.metadata.total_repositories_scanned' data/version_tags.json)
- Repositories with tags: $(jq -r '.statistics.total_repositories_with_tags' data/version_tags.json)

[skip ci]"
    
    # Commit changes
    git commit -m "$COMMIT_MSG"
    
    # Push to remote
    echo "🚀 Pushing changes to remote repository..."
    if git push origin "$DATA_BRANCH"; then
        echo "✅ Successfully pushed version data updates"
    else
        echo "❌ Failed to push changes"
        exit 1
    fi
fi

# Generate deployment report
echo "📋 Generating deployment report..."
cd "$DATA_DIR"
echo "Version Data Update Report" > report.txt
echo "========================" >> report.txt
echo "Date: $(date)" >> report.txt
echo "Organization: $ORG_NAME" >> report.txt
echo "Tag Version: $TAG_VERSION" >> report.txt
echo "" >> report.txt
echo "Summary:" >> report.txt
jq -r '.statistics | to_entries[] | "- \(.key): \(.value)"' data/version_tags.json >> report.txt
echo "" >> report.txt
echo "Tags found:" >> report.txt
jq -r '.tags | to_entries[] | "- \(.key): \(.value.summary.total_repositories) repositories"' data/version_tags.json >> report.txt

cat report.txt

echo ""
echo "✅ Version data update completed successfully!"
echo "📁 Data available at: $DATA_REPO"
echo "🔗 Files updated:"
echo "   - data/version_tags.json (main data file)"
echo "   - data/summary.json (UI summary)"
echo "   - data/*_deployments.json (environment-specific data)"
echo "   - schemas/version_tags.json (data schema)"
echo "========================================"

