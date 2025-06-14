#!/bin/bash

# Script to scan all git repositories and find tagged version 0.75.5
# Returns the commit ID for that tag

echo "Scanning for git repositories and looking for tag 0.75.5..."
echo "========================================================"

# Find all .git directories (repositories)
find . -name ".git" -type d 2>/dev/null | while read -r git_dir; do
    # Get the repository root directory
    repo_dir=$(dirname "$git_dir")
    
    echo "\nChecking repository: $repo_dir"
    
    # Change to repository directory
    cd "$repo_dir" || continue
    
    # Check if tag 0.75.5 exists
    if git tag -l | grep -q "^0\.75\.5$"; then
        echo "✓ Found tag 0.75.5 in repository: $repo_dir"
        
        # Get the commit ID for this tag
        commit_id=$(git rev-list -n 1 "0.75.5" 2>/dev/null)
        
        if [ -n "$commit_id" ]; then
            echo "  Commit ID: $commit_id"
            
            # Get additional info about the commit
            echo "  Commit details:"
            git show --no-patch --format="    Author: %an <%ae>%n    Date: %ad%n    Subject: %s" "$commit_id"
        else
            echo "  Error: Could not retrieve commit ID for tag 0.75.5"
        fi
        
        echo "  Repository path: $(pwd)"
    else
        echo "  Tag 0.75.5 not found"
    fi
    
    # Return to original directory
    cd - >/dev/null || exit 1
done

echo "\n========================================================"
echo "Scan complete."

