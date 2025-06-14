#!/bin/bash

# Script to scan all repositories in aira-technology GitHub organization
# and find tagged version 0.75.5, then get the commit ID

ORG_NAME="aira-technology"
TAG_VERSION="0.75.5"
TAG_VERSION_WITH_V="v0.75.5"

echo "Scanning GitHub organization: $ORG_NAME for tags: $TAG_VERSION and $TAG_VERSION_WITH_V"
echo "================================================================"

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

echo "Found repositories. Checking for tag $TAG_VERSION..."
echo

found_tag=false

# Process each repository
while IFS=' ' read -r repo_name repo_url; do
    echo "Checking repository: $repo_name"
    
    # Get tags for the repository
    tags=$(gh api "repos/$ORG_NAME/$repo_name/tags" --paginate 2>/dev/null | jq -r '.[].name' 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "  ⚠️  Could not access tags (may be private or restricted)"
        continue
    fi
    
    # Check if our target tags exist (both with and without 'v' prefix)
    found_current_tag=""
    
    if echo "$tags" | grep -q "^$TAG_VERSION$"; then
        found_current_tag="$TAG_VERSION"
    elif echo "$tags" | grep -q "^$TAG_VERSION_WITH_V$"; then
        found_current_tag="$TAG_VERSION_WITH_V"
    fi
    
    if [ -n "$found_current_tag" ]; then
        echo "  ✅ Found tag $found_current_tag!"
        found_tag=true
        
        # Get the commit SHA for this tag
        tag_info=$(gh api "repos/$ORG_NAME/$repo_name/git/refs/tags/$found_current_tag" 2>/dev/null)
        
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
            echo "  🏷️  Tag URL: $repo_url/releases/tag/$found_current_tag"
        else
            echo "  ❌ Could not retrieve commit information for tag"
        fi
        
        echo
    else
        echo "  ❌ Tags $TAG_VERSION and $TAG_VERSION_WITH_V not found"
    fi
    
done <<< "$repos"

echo "================================================================"
if [ "$found_tag" = true ]; then
    echo "✅ Search completed. Found tag $TAG_VERSION in the repositories above."
else
    echo "❌ Search completed. Tag $TAG_VERSION was not found in any repository."
fi

