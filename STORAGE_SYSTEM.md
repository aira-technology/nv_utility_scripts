# 🗄️ Version Tag Storage System Documentation

A comprehensive file storage and automation system for repository version tag data, designed for UI consumption and automated updates.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Storage Schema](#storage-schema)
3. [File Structure](#file-structure)
4. [Automation Scripts](#automation-scripts)
5. [GitHub Actions Workflow](#github-actions-workflow)
6. [Usage Examples](#usage-examples)
7. [UI Integration](#ui-integration)
8. [Deployment Setup](#deployment-setup)

## 🎯 Overview

This storage system provides:
- **Structured JSON storage** for version tag data
- **Automated data collection** via API and shell scripts
- **Git-based versioning** for data history and rollback
- **Multiple data formats** optimized for different UI needs
- **CI/CD integration** for automatic updates
- **Environment-specific filtering** for deployment tracking

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Scanner   │───▶│  Data Transform │───▶│   Git Storage   │
│                 │    │                 │    │                 │
│ • REST API      │    │ • JSON Schema   │    │ • version_tags  │
│ • Shell Scripts │    │ • Data Enhance  │    │ • summary.json  │
│ • Manual Scan   │    │ • Multi-format  │    │ • env_specific  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ▲                       │
                                │                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │ Deployment      │    │    UI/Web       │
                       │ Configuration   │    │   Application   │
                       │                 │    │                 │
                       │ • Status Info   │    │ • Read JSON     │
                       │ • Environment   │    │ • Display Data  │
                       │ • URLs          │    │ • Real-time     │
                       └─────────────────┘    └─────────────────┘
```

## 📊 Storage Schema

### Main Data Structure (`version_tags.json`)

```json
{
  "metadata": {
    "last_updated": "2025-06-15T04:24:58.000Z",
    "scan_duration_seconds": 45.2,
    "organization": "aira-technology",
    "total_repositories_scanned": 130,
    "scan_type": "specific_tag",
    "version": "1.0.0"
  },
  "tags": {
    "v0.75.5": {
      "tag_name": "v0.75.5",
      "repositories": [
        {
          "repository_name": "RANGPT_api",
          "commit_id": "a1b62cbae18224d0b8d7c7a737e9b19c235076f4",
          "commit_short": "a1b62cb",
          "author": "Felipe",
          "author_email": "felipe@aira-technology.com",
          "date": "2025-05-27T20:15:11Z",
          "message": "fix: hard fix wrong updatedAt...",
          "repository_url": "https://github.com/aira-technology/RANGPT_api",
          "tag_url": "https://github.com/aira-technology/RANGPT_api/releases/tag/v0.75.5",
          "deployment_status": "deployed",
          "environment": "production"
        }
      ],
      "summary": {
        "total_repositories": 12,
        "latest_commit_date": "2025-05-30T22:52:50Z",
        "deployment_environments": ["production", "staging"]
      }
    }
  },
  "statistics": {
    "total_unique_tags": 15,
    "total_repositories_with_tags": 25,
    "most_common_tag": "v0.75.5",
    "latest_tag_date": "2025-05-30T22:52:50Z"
  }
}
```

### Summary Format (`summary.json`)

```json
{
  "last_updated": "2025-06-15T04:24:58.000Z",
  "organization": "aira-technology",
  "total_tags": 15,
  "total_repositories": 25,
  "most_common_tag": "v0.75.5",
  "latest_tag_date": "2025-05-30T22:52:50Z",
  "scan_info": {
    "scan_type": "specific_tag",
    "duration_seconds": 45.2,
    "total_repositories_scanned": 130
  },
  "tags_overview": {
    "v0.75.5": {
      "repository_count": 12,
      "latest_commit_date": "2025-05-30T22:52:50Z",
      "environments": ["production", "staging"],
      "repositories": ["RANGPT_api", "nv_ai_core", "RANGPT-frontend"]
    }
  }
}
```

### Environment-Specific Format (`production_deployments.json`)

```json
{
  "environment": "production",
  "last_updated": "2025-06-15T04:24:58.000Z",
  "repositories": [
    {
      "repository_name": "RANGPT_api",
      "tag_name": "v0.75.5",
      "commit_short": "a1b62cb",
      "deployment_status": "deployed",
      "repository_url": "https://github.com/aira-technology/RANGPT_api",
      "tag_url": "https://github.com/aira-technology/RANGPT_api/releases/tag/v0.75.5",
      "author": "Felipe",
      "date": "2025-05-27T20:15:11Z"
    }
  ]
}
```

## 📁 File Structure

### Repository Layout

```
version-data/                 # Data repository
├── data/
│   ├── version_tags.json     # Complete version data
│   ├── summary.json          # UI summary
│   ├── production_deployments.json
│   ├── staging_deployments.json
│   ├── development_deployments.json
│   └── test_deployments.json
├── config/
│   └── deployment_config.json # Deployment configuration
├── schemas/
│   └── version_tags.json     # JSON schema
└── README.md                 # Documentation
```

### Utility Scripts Repository

```
nv_utility_scripts/
├── data_transformer.py       # Main data transformation script
├── update_version_data.sh    # Automated update script
├── schemas/
│   └── version_tags.json     # Schema definition
├── config/
│   └── deployment_config.json # Deployment configuration
├── data/
│   └── version_tags_example.json # Example data
└── .github/
    └── workflows/
        └── update-version-data.yml # GitHub Actions workflow
```

## 🔧 Automation Scripts

### 1. Data Transformer (`data_transformer.py`)

**Purpose:** Converts API responses to standardized storage format

**Usage:**
```bash
# Transform API data
python data_transformer.py \
  --api-url http://localhost:8000 \
  --organization aira-technology \
  --tag 0.75.5 \
  --output-file data/version_tags.json \
  --deployment-config config/deployment_config.json \
  --merge-existing

# Transform from file
python data_transformer.py \
  --input-file api_response.json \
  --output-file data/version_tags.json
```

**Features:**
- Converts API JSON to storage schema
- Enhances with deployment information
- Merges with existing data
- Generates statistics and summaries
- Creates environment-specific files

### 2. Automated Update Script (`update_version_data.sh`)

**Purpose:** End-to-end automation for data collection and Git updates

**Usage:**
```bash
# Basic usage
./update_version_data.sh

# With custom parameters
ORG_NAME="my-org" TAG_VERSION="1.0.0" ./update_version_data.sh

# With environment variables
export DATA_REPO="git@github.com:my-org/version-data.git"
export API_URL="https://api.mycompany.com"
./update_version_data.sh
```

**Features:**
- Automatic API server startup if needed
- Git repository cloning/updating
- Data transformation and enhancement
- Multiple output format generation
- Automated Git commits and pushes
- Comprehensive error handling
- Cleanup on exit

## 🚀 GitHub Actions Workflow

### Automated CI/CD Pipeline

The `update-version-data.yml` workflow provides:

**Triggers:**
- Manual dispatch with custom parameters
- Scheduled runs every 6 hours
- Repository dispatch events

**Steps:**
1. **Environment Setup** - Python, GitHub CLI, system dependencies
2. **API Server Start** - Launches the REST API in background
3. **Data Collection** - Fetches version tag data
4. **Data Transformation** - Converts to storage format
5. **Format Generation** - Creates summary and environment files
6. **Git Operations** - Commits and pushes to data repository
7. **Reporting** - Generates GitHub summary reports
8. **Cleanup** - Stops services and cleans temporary files

**Configuration:**
```yaml
env:
  ORG_NAME: 'aira-technology'
  TAG_VERSION: '0.75.5'
  DATA_REPO: 'aira-technology/version-data'
```

## 📱 Usage Examples

### Manual Data Update

```bash
# 1. Start API server
./start_api.sh

# 2. Transform data
python data_transformer.py \
  --organization aira-technology \
  --tag 0.75.5 \
  --output-file /tmp/version_data.json

# 3. Review the data
jq '.statistics' /tmp/version_data.json
```

### Scheduled Cron Job

```bash
# Add to crontab for daily updates at 2 AM
0 2 * * * cd /path/to/nv_utility_scripts && ./update_version_data.sh
```

### CI/CD Integration

```yaml
# Example GitHub Actions integration
- name: Update version data
  uses: ./.github/workflows/update-version-data.yml
  with:
    organization: 'my-org'
    tag_version: ${{ github.event.release.tag_name }}
    data_repository: 'my-org/version-data'
```

## 🖥️ UI Integration

### Frontend Data Consumption

#### React Example

```jsx
import React, { useState, useEffect } from 'react';

function VersionDashboard() {
  const [versionData, setVersionData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Fetch summary data for quick loading
    fetch('https://raw.githubusercontent.com/aira-technology/version-data/main/data/summary.json')
      .then(response => response.json())
      .then(data => {
        setVersionData(data);
        setLoading(false);
      })
      .catch(error => {
        console.error('Error fetching version data:', error);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading version data...</div>;
  if (!versionData) return <div>Error loading data</div>;

  return (
    <div className="version-dashboard">
      <h1>Version Dashboard</h1>
      <div className="stats">
        <div className="stat">
          <h3>{versionData.total_tags}</h3>
          <p>Total Tags</p>
        </div>
        <div className="stat">
          <h3>{versionData.total_repositories}</h3>
          <p>Repositories</p>
        </div>
        <div className="stat">
          <h3>{versionData.most_common_tag}</h3>
          <p>Most Common Tag</p>
        </div>
      </div>
      
      <h2>Tags Overview</h2>
      {Object.entries(versionData.tags_overview).map(([tag, info]) => (
        <div key={tag} className="tag-card">
          <h3>{tag}</h3>
          <p>Repositories: {info.repository_count}</p>
          <p>Environments: {info.environments.join(', ')}</p>
          <p>Latest: {new Date(info.latest_commit_date).toLocaleDateString()}</p>
        </div>
      ))}
    </div>
  );
}

export default VersionDashboard;
```

#### Environment-Specific Display

```jsx
function ProductionStatus() {
  const [prodData, setProdData] = useState(null);

  useEffect(() => {
    fetch('https://raw.githubusercontent.com/aira-technology/version-data/main/data/production_deployments.json')
      .then(response => response.json())
      .then(data => setProdData(data));
  }, []);

  return (
    <div className="production-status">
      <h2>Production Deployments</h2>
      <p>Last Updated: {new Date(prodData?.last_updated).toLocaleString()}</p>
      
      {prodData?.repositories.map(repo => (
        <div key={repo.repository_name} className="repo-card">
          <h3>{repo.repository_name}</h3>
          <p>Version: <span className="tag">{repo.tag_name}</span></p>
          <p>Commit: <code>{repo.commit_short}</code></p>
          <p>Author: {repo.author}</p>
          <div className="links">
            <a href={repo.repository_url} target="_blank">Repository</a>
            <a href={repo.tag_url} target="_blank">Release</a>
          </div>
        </div>
      ))}
    </div>
  );
}
```

### Vue.js Example

```vue
<template>
  <div class="version-tracker">
    <h1>Version Tracker</h1>
    
    <div v-if="loading" class="loading">Loading...</div>
    
    <div v-else class="content">
      <div class="summary">
        <h2>Summary</h2>
        <p>Organization: {{ summary.organization }}</p>
        <p>Total Tags: {{ summary.total_tags }}</p>
        <p>Total Repositories: {{ summary.total_repositories }}</p>
        <p>Last Updated: {{ formatDate(summary.last_updated) }}</p>
      </div>
      
      <div class="environments">
        <div v-for="env in environments" :key="env" class="env-section">
          <h3>{{ env.charAt(0).toUpperCase() + env.slice(1) }}</h3>
          <div v-for="repo in env.data?.repositories" :key="repo.repository_name" class="repo-item">
            <span class="repo-name">{{ repo.repository_name }}</span>
            <span class="tag-name">{{ repo.tag_name }}</span>
            <span class="commit">{{ repo.commit_short }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'VersionTracker',
  data() {
    return {
      summary: null,
      environments: [],
      loading: true
    }
  },
  async mounted() {
    await this.loadData();
  },
  methods: {
    async loadData() {
      try {
        // Load summary
        const summaryResponse = await fetch(
          'https://raw.githubusercontent.com/aira-technology/version-data/main/data/summary.json'
        );
        this.summary = await summaryResponse.json();
        
        // Load environment data
        const envs = ['production', 'staging', 'development', 'test'];
        this.environments = await Promise.all(
          envs.map(async env => {
            try {
              const response = await fetch(
                `https://raw.githubusercontent.com/aira-technology/version-data/main/data/${env}_deployments.json`
              );
              const data = await response.json();
              return { name: env, data };
            } catch {
              return { name: env, data: null };
            }
          })
        );
        
        this.loading = false;
      } catch (error) {
        console.error('Error loading data:', error);
        this.loading = false;
      }
    },
    formatDate(dateString) {
      return new Date(dateString).toLocaleString();
    }
  }
}
</script>
```

## ⚙️ Deployment Setup

### Prerequisites

1. **GitHub Repository Access**
   - Create a dedicated repository for version data (e.g., `aira-technology/version-data`)
   - Set up appropriate permissions for the automation bot/user

2. **GitHub Secrets**
   ```
   VERSION_DATA_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx  # Personal access token with repo access
   ```

3. **Local Environment**
   ```bash
   # Install dependencies
   pip install -r requirements.txt
   
   # Configure GitHub CLI
   gh auth login
   ```

### Step-by-Step Setup

#### 1. Create Data Repository

```bash
# Create the data repository
gh repo create aira-technology/version-data --public

# Clone and set up initial structure
git clone git@github.com:aira-technology/version-data.git
cd version-data
mkdir -p data config schemas
echo "# Version Data Repository" > README.md
git add .
git commit -m "Initial repository setup"
git push origin main
```

#### 2. Configure Deployment Settings

Create `config/deployment_config.json`:

```json
{
  "RANGPT_api": {
    "deployed_versions": {
      "v0.75.5": {
        "status": "deployed",
        "environment": "production",
        "deployed_at": "2025-06-10T14:30:00Z",
        "deployment_url": "https://api.prod.aira-technology.com"
      }
    },
    "repository_type": "backend_api",
    "team": "backend"
  }
}
```

#### 3. Set up Automation

**Option A: GitHub Actions (Recommended)**

1. Enable workflow in the utility scripts repository
2. Configure secrets in repository settings
3. Trigger manual run or wait for scheduled execution

**Option B: Cron Job**

```bash
# Add to crontab
crontab -e

# Add this line for daily updates at 2 AM
0 2 * * * cd /path/to/nv_utility_scripts && ./update_version_data.sh >> /var/log/version-update.log 2>&1
```

**Option C: Manual Updates**

```bash
# Set environment variables
export ORG_NAME="aira-technology"
export TAG_VERSION="0.75.5"
export DATA_REPO="git@github.com:aira-technology/version-data.git"

# Run update
./update_version_data.sh
```

#### 4. UI Integration

**For Static Sites (GitHub Pages, Netlify, etc.):**

```javascript
// Fetch data directly from GitHub raw URLs
const DATA_BASE_URL = 'https://raw.githubusercontent.com/aira-technology/version-data/main/data';

async function loadVersionData() {
  const summary = await fetch(`${DATA_BASE_URL}/summary.json`).then(r => r.json());
  const prodData = await fetch(`${DATA_BASE_URL}/production_deployments.json`).then(r => r.json());
  return { summary, prodData };
}
```

**For Server-Side Applications:**

```python
# Python example
import requests
import json
from functools import lru_cache
from datetime import datetime, timedelta

class VersionDataClient:
    def __init__(self, base_url="https://raw.githubusercontent.com/aira-technology/version-data/main/data"):
        self.base_url = base_url
        self._cache = {}
        self._cache_duration = timedelta(minutes=10)
    
    @lru_cache(maxsize=128)
    def get_summary(self):
        return self._fetch_json("summary.json")
    
    def get_environment_data(self, environment):
        return self._fetch_json(f"{environment}_deployments.json")
    
    def _fetch_json(self, filename):
        url = f"{self.base_url}/{filename}"
        response = requests.get(url)
        response.raise_for_status()
        return response.json()

# Usage
client = VersionDataClient()
summary = client.get_summary()
production_data = client.get_environment_data("production")
```

### Monitoring and Maintenance

1. **Monitor GitHub Actions**
   - Check workflow runs in the Actions tab
   - Review summary reports
   - Set up notifications for failures

2. **Data Quality Checks**
   ```bash
   # Validate JSON schema
   ajv validate -s schemas/version_tags.json -d data/version_tags.json
   
   # Check data freshness
   python3 -c "
   import json
   from datetime import datetime, timedelta
   
   with open('data/summary.json') as f:
       data = json.load(f)
   
   last_updated = datetime.fromisoformat(data['last_updated'].replace('Z', '+00:00'))
   if datetime.now(last_updated.tzinfo) - last_updated > timedelta(hours=12):
       print('WARNING: Data is stale')
   else:
       print('Data is fresh')
   "
   ```

3. **Backup Strategy**
   - Git history provides natural backup
   - Consider periodic exports to other storage
   - Monitor repository size growth

---

## 🎉 Benefits

- **🔄 Automated Updates**: No manual intervention required
- **📊 Structured Data**: Consistent JSON format for easy parsing
- **🌍 Multiple Formats**: Optimized for different UI needs
- **🔍 Version Control**: Full history and rollback capabilities
- **🚀 Easy Integration**: Simple HTTP requests to fetch data
- **📱 Responsive**: Fast loading with summary files
- **🔒 Secure**: Token-based authentication and permissions
- **📈 Scalable**: Handles large organizations efficiently

This storage system provides a complete solution for version tag management, from automated collection to UI consumption, ensuring your applications always have access to the latest repository version information! 🚀

