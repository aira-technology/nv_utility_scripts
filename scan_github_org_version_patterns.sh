#!/bin/bash

# Enhanced script to scan all repositories in aira-technology GitHub organization
# and find version tags matching patterns around 0.75.5

ORG_NAME="aira-technology"
TARGET_VERSION="0.75.5"

echo "Scanning GitHub organization: $ORG_NAME for version patterns around: $TARGET_VERSION"
echo "=========================================================================="

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install it with: brew install gh"
    echo "Then authenticate with: gh auth login"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "Fetching repositories from organization: $ORG_NAME..."
echo

# Get all repositories in the organization
repos=$(gh repo list "$ORG_NAME" --limit 1000 --json name,url | jq -r '.[] | "\(.name) \(.url)"')

if [ -z "$repos" ]; then
    echo "No repositories found or unable to access organization: $ORG_NAME"
    exit 1
fi

echo "Found repositories. Searching for version patterns..."
echo

found_exact=false
found_similar=false

# Process each repository
while IFS=' ' read -r repo_name repo_url; do
    echo "Checking repository: $repo_name"
    
    # Get tags for the repository
    tags=$(gh api "repos/$ORG_NAME/$repo_name/tags" --paginate 2>/dev/null | jq -r '.[].name' 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "  ⚠️  Could not access tags (may be private or restricted)"
        continue
    fi
    
    if [ -z "$tags" ]; then
        echo "  📝 No tags found"
        continue
    fi
    
    # Check for exact match first
    if echo "$tags" | grep -q "^$TARGET_VERSION$"; then
        echo "  ✅ Found exact tag $TARGET_VERSION!"
        found_exact=true
        
        # Get the commit SHA for this tag
        tag_info=$(gh api "repos/$ORG_NAME/$repo_name/git/refs/tags/$TARGET_VERSION" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            commit_sha=$(echo "$tag_info" | jq -r '.object.sha')
            echo "  📋 Commit ID: $commit_sha"
            
            # Get commit details
            commit_info=$(gh api "repos/$ORG_NAME/$repo_name/commits/$commit_sha" 2>/dev/null)
            if [ $? -eq 0 ]; then
                author=$(echo "$commit_info" | jq -r '.commit.author.name')
                date=$(echo "$commit_info" | jq -r '.commit.author.date')
                message=$(echo "$commit_info" | jq -r '.commit.message' | head -1)
                
                echo "  👤 Author: $author"
                echo "  📅 Date: $date"
                echo "  💬 Message: $message"
            fi
            
            echo "  🔗 Repository: $repo_url"
            echo "  🏷️  Tag URL: $repo_url/releases/tag/$TARGET_VERSION"
        fi
        echo
    else
        # Look for similar version patterns
        similar_tags=$(echo "$tags" | grep -E "(0\.75\.|v0\.75\.|75\.5|0\.7[0-9]\.|v0\.7[0-9]\.)" | head -5)
        
        if [ -n "$similar_tags" ]; then
            echo "  🔍 Similar version tags found:"
            echo "$similar_tags" | while read -r tag; do
                if [ -n "$tag" ]; then
                    echo "    - $tag"
                fi
            done
            found_similar=true
        else
            # Show some recent tags for context
            recent_tags=$(echo "$tags" | head -3)
            if [ -n "$recent_tags" ]; then
                echo "  📌 Recent tags (showing first 3):"
                echo "$recent_tags" | while read -r tag; do
                    if [ -n "$tag" ]; then
                        echo "    - $tag"
                    fi
                done
            fi
        fi
    fi
    
done <<< "$repos"

echo "=========================================================================="
if [ "$found_exact" = true ]; then
    echo "✅ Found exact tag $TARGET_VERSION in the repositories above."
elif [ "$found_similar" = true ]; then
    echo "🔍 No exact match for $TARGET_VERSION, but found similar version patterns."
else
    echo "❌ No exact match or similar version patterns found for $TARGET_VERSION."
fi

echo
echo "💡 Tip: If you know the specific repository name, you can search more efficiently:"
echo "   gh api repos/aira-technology/REPO_NAME/tags | jq -r '.[].name' | grep -i 75"

