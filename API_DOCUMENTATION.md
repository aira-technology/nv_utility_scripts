# Repository Tag Scanner REST API Documentation

A FastAPI-based REST API that provides the same functionality as our shell scripts for scanning repositories and finding version tags.

## 🚀 Quick Start

### Installation & Setup

1. **Install dependencies:**
   ```bash
   # Make sure you have GitHub CLI installed and authenticated
   brew install gh
   gh auth login
   
   # Start the API server
   ./start_api.sh
   ```

2. **Access the API:**
   - **API Base URL:** http://localhost:8000
   - **Interactive Documentation:** http://localhost:8000/docs
   - **Alternative Documentation:** http://localhost:8000/redoc

## 📋 API Endpoints

### 1. Health Check

**GET** `/api/v1/health`

Checks the health status of the API and its dependencies.

**Response:**
```json
{
    "status": "healthy",
    "timestamp": "2025-06-14T21:00:00.000Z",
    "github_cli_available": true,
    "git_available": true
}
```

**Example:**
```bash
curl http://localhost:8000/api/v1/health
```

---

### 2. Scan Organization for Specific Tag

**GET** `/api/v1/scan/organization/{org_name}/tag/{tag_version}`

Scans all repositories in a GitHub organization for a specific tag version.

**Parameters:**
- `org_name` (path): GitHub organization name (e.g., "aira-technology")
- `tag_version` (path): Tag version to search for (e.g., "0.75.5")
- `include_patterns` (query, optional): Include both 'x.y.z' and 'vx.y.z' patterns (default: true)

**Response:**
```json
{
    "total_repositories_scanned": 130,
    "repositories_with_tag": 12,
    "tags_found": [
        {
            "tag_name": "v0.75.5",
            "commit_id": "a1b62cbae18224d0b8d7c7a737e9b19c235076f4",
            "author": "Felipe",
            "date": "2025-05-27T20:15:11Z",
            "message": "fix: hard fix wrong updatedAt being passed on routine creation",
            "repository_name": "RANGPT_api",
            "repository_url": "https://github.com/aira-technology/RANGPT_api",
            "tag_url": "https://github.com/aira-technology/RANGPT_api/releases/tag/v0.75.5"
        }
    ],
    "scan_timestamp": "2025-06-14T21:00:00.000Z",
    "scan_duration_seconds": 45.2
}
```

**Examples:**
```bash
# Find v0.75.5 in aira-technology organization
curl http://localhost:8000/api/v1/scan/organization/aira-technology/tag/0.75.5

# Find exact tag without pattern matching
curl "http://localhost:8000/api/v1/scan/organization/aira-technology/tag/v0.75.5?include_patterns=false"
```

---

### 3. Scan Local Repositories for Tag

**GET** `/api/v1/scan/local/tag/{tag_version}`

Scans local git repositories for a specific tag version.

**Parameters:**
- `tag_version` (path): Tag version to search for (e.g., "0.75.5")
- `base_path` (query, optional): Base path to start scanning from (default: ".")

**Response:**
```json
{
    "total_repositories_scanned": 15,
    "repositories_with_tag": 2,
    "tags_found": [
        {
            "tag_name": "v0.75.5",
            "commit_id": "abc123...",
            "author": "Developer Name",
            "date": "2025-05-27T20:15:11Z",
            "message": "Release v0.75.5",
            "repository_name": "my-local-repo",
            "repository_url": "file:///Users/siva/my-local-repo",
            "tag_url": "file:///Users/siva/my-local-repo/.git/refs/tags/v0.75.5",
            "repository_path": "/Users/siva/my-local-repo"
        }
    ],
    "scan_timestamp": "2025-06-14T21:00:00.000Z",
    "scan_duration_seconds": 2.1
}
```

**Examples:**
```bash
# Scan current directory and subdirectories
curl http://localhost:8000/api/v1/scan/local/tag/0.75.5

# Scan specific directory
curl "http://localhost:8000/api/v1/scan/local/tag/0.75.5?base_path=/Users/siva/projects"
```

---

### 4. Scan Organization for Version Patterns

**GET** `/api/v1/scan/organization/{org_name}/patterns/{version_pattern}`

Scans organization repositories for tags matching a version pattern (e.g., all 0.75.x versions).

**Parameters:**
- `org_name` (path): GitHub organization name
- `version_pattern` (path): Version pattern to search for (e.g., "0.75" for 0.75.x)
- `max_results` (query, optional): Maximum number of results to return (default: 50)

**Response:**
```json
{
    "total_repositories_scanned": 130,
    "repositories_with_tag": 8,
    "tags_found": [
        {
            "tag_name": "v0.75.0",
            "commit_id": "def456...",
            "author": "Developer",
            "date": "2025-05-20T10:00:00Z",
            "message": "Release v0.75.0",
            "repository_name": "RANGPT_api",
            "repository_url": "https://github.com/aira-technology/RANGPT_api",
            "tag_url": "https://github.com/aira-technology/RANGPT_api/releases/tag/v0.75.0"
        },
        {
            "tag_name": "v0.75.5",
            "commit_id": "a1b62c...",
            "repository_name": "RANGPT_api",
            ...
        }
    ],
    "scan_timestamp": "2025-06-14T21:00:00.000Z",
    "scan_duration_seconds": 52.8
}
```

**Examples:**
```bash
# Find all 0.75.x versions
curl http://localhost:8000/api/v1/scan/organization/aira-technology/patterns/0.75

# Find all 1.0.x versions, limit to 20 results
curl "http://localhost:8000/api/v1/scan/organization/aira-technology/patterns/1.0?max_results=20"
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
# Edit .env with your preferences
```

### Prerequisites

1. **GitHub CLI (required for organization scanning):**
   ```bash
   brew install gh
   gh auth login
   ```

2. **Git (required for local scanning):**
   ```bash
   # Usually pre-installed on macOS
   git --version
   ```

3. **Python 3.8+ (required):**
   ```bash
   python3 --version
   ```

## 🚀 Running the API

### Development Mode
```bash
# Using the startup script (recommended)
./start_api.sh

# Or manually
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

### Production Mode
```bash
# Using uvicorn directly
uvicorn app:app --host 0.0.0.0 --port 8000 --workers 4
```

### Docker (optional)
```bash
# Build image
docker build -t repo-tag-scanner .

# Run container
docker run -p 8000:8000 repo-tag-scanner
```

## 📊 API Usage Examples

### Using curl

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Find v0.75.5 in aira-technology
curl http://localhost:8000/api/v1/scan/organization/aira-technology/tag/0.75.5

# Scan local repositories
curl http://localhost:8000/api/v1/scan/local/tag/0.75.5

# Find version patterns
curl http://localhost:8000/api/v1/scan/organization/aira-technology/patterns/0.75
```

### Using Python requests

```python
import requests

# Health check
response = requests.get("http://localhost:8000/api/v1/health")
print(response.json())

# Scan organization
response = requests.get(
    "http://localhost:8000/api/v1/scan/organization/aira-technology/tag/0.75.5"
)
result = response.json()
print(f"Found {result['repositories_with_tag']} repositories with tag")

for tag in result['tags_found']:
    print(f"- {tag['repository_name']}: {tag['commit_id']}")
```

### Using JavaScript/Node.js

```javascript
// Using fetch API
fetch('http://localhost:8000/api/v1/scan/organization/aira-technology/tag/0.75.5')
  .then(response => response.json())
  .then(data => {
    console.log(`Found ${data.repositories_with_tag} repositories`);
    data.tags_found.forEach(tag => {
      console.log(`${tag.repository_name}: ${tag.commit_id}`);
    });
  });
```

## 🛠️ Error Handling

### Common Error Responses

**GitHub CLI not authenticated (500):**
```json
{
    "error": "Internal Server Error",
    "details": "GitHub CLI not available or not authenticated"
}
```

**Repository not found (500):**
```json
{
    "error": "Internal Server Error",
    "details": "GitHub CLI error: repository not found"
}
```

**Invalid endpoint (404):**
```json
{
    "error": "Not Found",
    "details": "The requested endpoint was not found"
}
```

## 🔍 Monitoring & Logging

The API includes:
- Request/response logging
- Performance metrics (scan duration)
- Health checks for dependencies
- Error tracking and details

## 🚀 Performance Notes

- **Organization scans:** ~30-60 seconds for 100+ repositories
- **Local scans:** ~1-5 seconds depending on repository count
- **Pattern scans:** ~45-90 seconds for complex patterns
- **Concurrent requests:** Supported (GitHub API rate limits apply)

## 🤝 Integration Examples

### CI/CD Pipeline
```yaml
# Example GitHub Actions workflow
- name: Check tag existence
  run: |
    response=$(curl -s http://api-server:8000/api/v1/scan/organization/aira-technology/tag/${{ github.ref_name }})
    if [ $(echo $response | jq '.repositories_with_tag') -gt 0 ]; then
      echo "Tag found in repositories"
    fi
```

### Web Dashboard
```html
<!-- Simple web interface -->
<script>
function scanForTag() {
    const org = document.getElementById('org').value;
    const tag = document.getElementById('tag').value;
    
    fetch(`/api/v1/scan/organization/${org}/tag/${tag}`)
        .then(response => response.json())
        .then(data => displayResults(data));
}
</script>
```

## 🔧 Troubleshooting

### Common Issues

1. **"GitHub CLI not found"**
   - Install: `brew install gh`
   - Authenticate: `gh auth login`

2. **"Git not available"**
   - Install Git or check PATH

3. **API server won't start**
   - Check if port 8000 is available
   - Verify Python dependencies are installed

4. **Slow response times**
   - Large organizations take longer to scan
   - Use pattern endpoints for better performance
   - Consider caching results

---

## 📝 API Equivalents to Shell Scripts

| Shell Script | API Endpoint | Description |
|-------------|-------------|-------------|
| `scan_github_org_tags.sh` | `GET /api/v1/scan/organization/{org}/tag/{tag}` | Main organization scanner |
| `find_tag_commit.sh` | `GET /api/v1/scan/local/tag/{tag}` | Local repository scanner |
| `scan_github_org_version_patterns.sh` | `GET /api/v1/scan/organization/{org}/patterns/{pattern}` | Pattern matching scanner |

The API provides the same functionality as the shell scripts but with:
- ✅ Structured JSON responses
- ✅ HTTP status codes for error handling
- ✅ Better error messages and debugging info
- ✅ Interactive documentation
- ✅ Easy integration with other systems
- ✅ Performance metrics and timing info

