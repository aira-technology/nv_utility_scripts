#!/bin/bash

# Script to add branch protection for feature/v1.0-release branch
# Requires GitHub CLI (gh) to be installed and authenticated

set -e

BRANCH_NAME="feature/v1.0-release"
REPO_OWNER="aira-technology"
REPO_NAME="version-data"

echo "🔒 Adding branch protection for $BRANCH_NAME..."

# Check if GitHub CLI is authenticated
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
fi

# Check if branch exists, create if it doesn't
echo "📋 Checking if branch exists..."
if ! git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    echo "📝 Branch $BRANCH_NAME doesn't exist locally. Creating it..."
    git checkout -b $BRANCH_NAME
    git push -u origin $BRANCH_NAME
    echo "✅ Branch $BRANCH_NAME created and pushed to remote"
else
    echo "✅ Branch $BRANCH_NAME already exists"
fi

# Create protection config file
cat > protection_config.json << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 2,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# Add branch protection rule
gh api --method PUT /repos/$REPO_OWNER/$REPO_NAME/branches/feature%2Fv1.0-release/protection --input protection_config.json

# Clean up config file
rm -f protection_config.json

echo "✅ Branch protection successfully added for $BRANCH_NAME"
echo ""
echo "📋 Protection rules applied:"
echo "   • Required approving reviews: 2"
echo "   • Dismiss stale reviews: enabled"
echo "   • Force pushes: disabled"
echo "   • Branch deletions: disabled"
echo "   • Admin enforcement: disabled"
echo ""
echo "🔗 View branch protection settings:"
echo "   https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"

