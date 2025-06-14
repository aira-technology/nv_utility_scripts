# NV Utility Scripts

A collection of utility scripts for managing and scanning repositories, particularly for version tag discovery and repository management tasks.

## 📁 Scripts Overview

### 1. **find_tag_commit.sh**
**Purpose:** Scans local git repositories for a specific tag and retrieves commit information.

**Usage:**
```bash
./find_tag_commit.sh
```

**Features:**
- Recursively finds all `.git` directories in the current path
- Searches for tag `0.75.5` in each repository
- Displays commit ID, author, date, and subject for found tags
- Shows repository paths for easy navigation

---

### 2. **scan_github_org_tags.sh** ⭐
**Purpose:** Scans all repositories in a GitHub organization for specific version tags.

**Usage:**
```bash
./scan_github_org_tags.sh
```

**Features:**
- Searches for both `0.75.5` and `v0.75.5` tag patterns
- Uses GitHub CLI for efficient API access
- Retrieves detailed commit information (ID, author, date, message)
- Provides direct links to repository and release pages
- Handles authentication and error cases gracefully
- Supports large organizations with pagination

**Configuration:**
- Organization: `aira-technology` (configurable in script)
- Target version: `0.75.5` (configurable in script)

---

### 3. **scan_github_org_version_patterns.sh**
**Purpose:** Enhanced version scanner that looks for similar version patterns when exact matches aren't found.

**Usage:**
```bash
./scan_github_org_version_patterns.sh
```

**Features:**
- Searches for exact tag match first
- Falls back to similar version patterns (0.75.x, v0.75.x, 75.5, etc.)
- Shows recent tags from repositories for context
- Provides tips for more targeted searches
- Comprehensive pattern matching with regex

---

### 4. **REST API (app.py)** 🆕 ⭐
**Purpose:** FastAPI-based REST API that provides the same functionality as the shell scripts via HTTP endpoints.

**Usage:**
```bash
# Start the API server
./start_api.sh

# Access interactive documentation
open http://localhost:8000/docs
```

**Endpoints:**
- `GET /api/v1/health` - Health check
- `GET /api/v1/scan/organization/{org}/tag/{tag}` - Scan organization for specific tag
- `GET /api/v1/scan/local/tag/{tag}` - Scan local repositories
- `GET /api/v1/scan/organization/{org}/patterns/{pattern}` - Pattern matching

**Features:**
- 🌐 RESTful HTTP API with JSON responses
- 📚 Interactive Swagger documentation
- ⚡ Same functionality as shell scripts
- 🔧 Easy integration with other systems
- 📊 Performance metrics and error handling
- 🐳 Docker support included

---

## 🚀 Prerequisites

### Required Tools
1. **GitHub CLI (gh)**
   ```bash
   # Install on macOS
   brew install gh
   
   # Authenticate
   gh auth login
   ```

2. **jq** (JSON processor)
   ```bash
   # Install on macOS
   brew install jq
   ```

3. **Git** (for local repository scanning)

### Permissions
- GitHub CLI must be authenticated with appropriate permissions
- Access to the target GitHub organization repositories

---

## 📋 Usage Examples

### Find v0.75.5 in aira-technology organization
```bash
# Run the main scanner
./scan_github_org_tags.sh

# Expected output for successful finds:
# ✅ Found tag v0.75.5!
# 📋 Commit ID: a1b62cbae18224d0b8d7c7a737e9b19c235076f4
# 👤 Author: Felipe
# 📅 Date: 2025-05-27T20:15:11Z
# 💬 Message: fix: hard fix wrong updatedAt being passed on routine creation
# 🔗 Repository: https://github.com/aira-technology/RANGPT_api
# 🏷️ Tag URL: https://github.com/aira-technology/RANGPT_api/releases/tag/v0.75.5
```

### Search for specific repository tags
```bash
# Direct API call for specific repository
gh api repos/aira-technology/RANGPT_api/tags | jq -r '.[].name' | grep -i 75
```

### Scan local repositories
```bash
# Scan all local git repositories
./find_tag_commit.sh
```

---

## 🛠️ Customization

### Modify target organization
Edit the `ORG_NAME` variable in the scripts:
```bash
ORG_NAME="your-organization-name"
```

### Change target version
Edit the `TAG_VERSION` variables:
```bash
TAG_VERSION="1.0.0"
TAG_VERSION_WITH_V="v1.0.0"
```

### Add more version patterns
Modify the grep pattern in `scan_github_org_version_patterns.sh`:
```bash
similar_tags=$(echo "$tags" | grep -E "(1\.0\.|v1\.0\.|your-pattern)" | head -5)
```

---

## 🎯 Recent Success Story

**Challenge:** Find tag `0.75.5` in aira-technology organization  
**Issue:** Script initially missed tags because they were prefixed with 'v'  
**Solution:** Enhanced script to search for both `0.75.5` and `v0.75.5`  
**Result:** ✅ Successfully found v0.75.5 in 12 repositories including:

- RANGPT_api (commit: `a1b62cbae18224d0b8d7c7a737e9b19c235076f4`)
- nv_ai_core (commit: `d5a0daad8507d61d928fdb693ba916c83722b543`)
- RANGPT-frontend (commit: `8898c0663ed6f589855577cfc614ca4b6dcd98ea`)
- And 9 more repositories

---

## 🔧 Troubleshooting

### Common Issues

1. **"gh: command not found"**
   ```bash
   brew install gh
   gh auth login
   ```

2. **"jq: command not found"**
   ```bash
   brew install jq
   ```

3. **"Not authenticated with GitHub CLI"**
   ```bash
   gh auth login
   gh auth status  # Verify authentication
   ```

4. **"No repositories found"**
   - Check organization name spelling
   - Verify access permissions to the organization
   - Ensure organization exists and is accessible

5. **"Could not access tags (may be private or restricted)"**
   - Repository might be private
   - Check if you have appropriate access permissions

---

## 📊 Performance Notes

- Scripts use GitHub API pagination for large organizations
- Rate limiting is handled automatically by GitHub CLI
- Local repository scanning is recursive and may take time for large directory structures
- API calls are optimized to minimize requests while gathering comprehensive information

---

## 🤝 Contributing

Feel free to enhance these scripts by:
- Adding support for other version control systems
- Implementing parallel processing for faster scanning
- Adding more flexible pattern matching
- Creating additional utility functions

---

## 📝 License

These utility scripts are provided as-is for internal use within the organization.

---

## 🏷️ Version History

- **v1.0** - Initial local repository scanner
- **v1.1** - Added GitHub organization scanning
- **v1.2** - Fixed version prefix handling (v0.75.5 vs 0.75.5)
- **v1.3** - Added enhanced pattern matching and error handling

