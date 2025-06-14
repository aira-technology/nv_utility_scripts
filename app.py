#!/usr/bin/env python3
"""
Repository Tag Scanner REST API

A FastAPI-based REST API that provides the same functionality as the shell scripts
for scanning repositories and finding version tags.

Endpoints:
- GET /api/v1/scan/organization/{org_name}/tag/{tag_version}
- GET /api/v1/scan/local/tag/{tag_version}
- GET /api/v1/scan/organization/{org_name}/patterns/{version_pattern}
- GET /api/v1/health
"""

import os
import subprocess
import json
from typing import List, Dict, Optional, Any
from pathlib import Path
import re
from datetime import datetime

from fastapi import FastAPI, HTTPException, Query, Path
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import requests
from git import Repo, InvalidGitRepositoryError
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="Repository Tag Scanner API",
    description="REST API for scanning repositories and finding version tags",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Pydantic models
class TagInfo(BaseModel):
    """Information about a found tag"""
    tag_name: str = Field(..., description="The name of the tag")
    commit_id: str = Field(..., description="The commit SHA associated with the tag")
    author: Optional[str] = Field(None, description="Author of the commit")
    date: Optional[str] = Field(None, description="Date of the commit")
    message: Optional[str] = Field(None, description="Commit message")
    repository_name: str = Field(..., description="Name of the repository")
    repository_url: str = Field(..., description="URL of the repository")
    tag_url: str = Field(..., description="URL to the tag/release")
    repository_path: Optional[str] = Field(None, description="Local path for local repos")

class ScanResult(BaseModel):
    """Result of a repository scan"""
    total_repositories_scanned: int = Field(..., description="Total number of repositories scanned")
    repositories_with_tag: int = Field(..., description="Number of repositories with the target tag")
    tags_found: List[TagInfo] = Field(..., description="List of found tags")
    scan_timestamp: str = Field(..., description="Timestamp of the scan")
    scan_duration_seconds: Optional[float] = Field(None, description="Duration of the scan in seconds")

class ErrorResponse(BaseModel):
    """Error response model"""
    error: str = Field(..., description="Error message")
    details: Optional[str] = Field(None, description="Additional error details")

class HealthResponse(BaseModel):
    """Health check response"""
    status: str = Field(..., description="Service status")
    timestamp: str = Field(..., description="Current timestamp")
    github_cli_available: bool = Field(..., description="Whether GitHub CLI is available")
    git_available: bool = Field(..., description="Whether Git is available")

# Utility functions
def check_github_cli() -> bool:
    """Check if GitHub CLI is available and authenticated"""
    try:
        result = subprocess.run(["gh", "auth", "status"], 
                              capture_output=True, text=True, timeout=10)
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False

def check_git() -> bool:
    """Check if Git is available"""
    try:
        result = subprocess.run(["git", "--version"], 
                              capture_output=True, text=True, timeout=5)
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False

def run_gh_command(command: List[str]) -> Dict[str, Any]:
    """Run a GitHub CLI command and return the result"""
    try:
        result = subprocess.run(["gh"] + command, 
                              capture_output=True, text=True, timeout=60)
        if result.returncode != 0:
            raise HTTPException(status_code=500, 
                              detail=f"GitHub CLI error: {result.stderr}")
        return json.loads(result.stdout) if result.stdout.strip() else {}
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, 
                          detail="GitHub CLI command timed out")
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=500, 
                          detail=f"Failed to parse GitHub CLI response: {str(e)}")
    except FileNotFoundError:
        raise HTTPException(status_code=500, 
                          detail="GitHub CLI not found. Please install 'gh' CLI")

def get_repositories(org_name: str) -> List[Dict[str, str]]:
    """Get all repositories for an organization"""
    repos_data = run_gh_command(["repo", "list", org_name, "--limit", "1000", "--json", "name,url"])
    return repos_data if isinstance(repos_data, list) else []

def get_repository_tags(org_name: str, repo_name: str) -> List[str]:
    """Get tags for a specific repository"""
    try:
        tags_data = run_gh_command(["api", f"repos/{org_name}/{repo_name}/tags", "--paginate"])
        if isinstance(tags_data, list):
            return [tag.get('name', '') for tag in tags_data if tag.get('name')]
        return []
    except HTTPException as e:
        # Repository might be private or inaccessible
        if "404" in str(e.detail):
            return []
        raise

def get_tag_commit_info(org_name: str, repo_name: str, tag_name: str) -> Optional[Dict[str, Any]]:
    """Get commit information for a specific tag"""
    try:
        # Get tag reference
        tag_ref = run_gh_command(["api", f"repos/{org_name}/{repo_name}/git/refs/tags/{tag_name}"])
        commit_sha = tag_ref.get('object', {}).get('sha')
        
        if not commit_sha:
            return None
            
        # Get commit details
        commit_info = run_gh_command(["api", f"repos/{org_name}/{repo_name}/commits/{commit_sha}"])
        
        return {
            'commit_sha': commit_sha,
            'author': commit_info.get('commit', {}).get('author', {}).get('name'),
            'date': commit_info.get('commit', {}).get('author', {}).get('date'),
            'message': commit_info.get('commit', {}).get('message', '').split('\n')[0]  # First line only
        }
    except HTTPException:
        return None

def find_local_git_repositories(base_path: str = ".") -> List[str]:
    """Find all local git repositories"""
    git_repos = []
    base_path = Path(base_path).resolve()
    
    try:
        for item in base_path.rglob(".git"):
            if item.is_dir():
                repo_path = item.parent
                git_repos.append(str(repo_path))
    except PermissionError:
        pass  # Skip directories we can't access
        
    return git_repos

def scan_local_repository_for_tag(repo_path: str, tag_version: str) -> Optional[TagInfo]:
    """Scan a local repository for a specific tag"""
    try:
        repo = Repo(repo_path)
        
        # Check for both tag patterns
        tag_patterns = [tag_version, f"v{tag_version}"]
        
        for pattern in tag_patterns:
            try:
                tag = repo.tag(pattern)
                commit = tag.commit
                
                return TagInfo(
                    tag_name=pattern,
                    commit_id=str(commit.hexsha),
                    author=commit.author.name if commit.author else None,
                    date=datetime.fromtimestamp(commit.committed_date).isoformat(),
                    message=commit.message.split('\n')[0] if commit.message else None,
                    repository_name=Path(repo_path).name,
                    repository_url=f"file://{repo_path}",
                    tag_url=f"file://{repo_path}/.git/refs/tags/{pattern}",
                    repository_path=repo_path
                )
            except:
                continue  # Tag doesn't exist, try next pattern
                
    except InvalidGitRepositoryError:
        pass  # Not a git repository
    except Exception:
        pass  # Other git errors
        
    return None

# API Routes
@app.get("/api/v1/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        github_cli_available=check_github_cli(),
        git_available=check_git()
    )

@app.get("/api/v1/scan/organization/{org_name}/tag/{tag_version}", response_model=ScanResult)
async def scan_organization_for_tag(
    org_name: str = Path(..., description="GitHub organization name"),
    tag_version: str = Path(..., description="Tag version to search for (e.g., '0.75.5')"),
    include_patterns: bool = Query(True, description="Include both 'x.y.z' and 'vx.y.z' patterns")
):
    """Scan all repositories in a GitHub organization for a specific tag"""
    start_time = datetime.now()
    
    if not check_github_cli():
        raise HTTPException(status_code=500, 
                          detail="GitHub CLI not available or not authenticated")
    
    try:
        # Get all repositories
        repositories = get_repositories(org_name)
        total_repos = len(repositories)
        found_tags = []
        
        tag_patterns = [tag_version]
        if include_patterns and not tag_version.startswith('v'):
            tag_patterns.append(f"v{tag_version}")
        
        for repo in repositories:
            repo_name = repo.get('name', '')
            repo_url = repo.get('url', '')
            
            if not repo_name:
                continue
                
            # Get tags for this repository
            tags = get_repository_tags(org_name, repo_name)
            
            # Check if any of our target patterns exist
            for pattern in tag_patterns:
                if pattern in tags:
                    commit_info = get_tag_commit_info(org_name, repo_name, pattern)
                    
                    tag_info = TagInfo(
                        tag_name=pattern,
                        commit_id=commit_info.get('commit_sha', '') if commit_info else '',
                        author=commit_info.get('author') if commit_info else None,
                        date=commit_info.get('date') if commit_info else None,
                        message=commit_info.get('message') if commit_info else None,
                        repository_name=repo_name,
                        repository_url=repo_url,
                        tag_url=f"{repo_url}/releases/tag/{pattern}"
                    )
                    found_tags.append(tag_info)
                    break  # Found a match, no need to check other patterns
        
        duration = (datetime.now() - start_time).total_seconds()
        
        return ScanResult(
            total_repositories_scanned=total_repos,
            repositories_with_tag=len(found_tags),
            tags_found=found_tags,
            scan_timestamp=start_time.isoformat(),
            scan_duration_seconds=duration
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Scan failed: {str(e)}")

@app.get("/api/v1/scan/local/tag/{tag_version}", response_model=ScanResult)
async def scan_local_repositories_for_tag(
    tag_version: str = Path(..., description="Tag version to search for (e.g., '0.75.5')"),
    base_path: str = Query(".", description="Base path to start scanning from")
):
    """Scan local git repositories for a specific tag"""
    start_time = datetime.now()
    
    if not check_git():
        raise HTTPException(status_code=500, detail="Git not available")
    
    try:
        # Find all local git repositories
        git_repos = find_local_git_repositories(base_path)
        total_repos = len(git_repos)
        found_tags = []
        
        for repo_path in git_repos:
            tag_info = scan_local_repository_for_tag(repo_path, tag_version)
            if tag_info:
                found_tags.append(tag_info)
        
        duration = (datetime.now() - start_time).total_seconds()
        
        return ScanResult(
            total_repositories_scanned=total_repos,
            repositories_with_tag=len(found_tags),
            tags_found=found_tags,
            scan_timestamp=start_time.isoformat(),
            scan_duration_seconds=duration
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Local scan failed: {str(e)}")

@app.get("/api/v1/scan/organization/{org_name}/patterns/{version_pattern}", response_model=ScanResult)
async def scan_organization_for_patterns(
    org_name: str = Path(..., description="GitHub organization name"),
    version_pattern: str = Path(..., description="Version pattern to search for (e.g., '0.75' for 0.75.x)"),
    max_results: int = Query(50, description="Maximum number of results to return")
):
    """Scan organization repositories for tags matching a version pattern"""
    start_time = datetime.now()
    
    if not check_github_cli():
        raise HTTPException(status_code=500, 
                          detail="GitHub CLI not available or not authenticated")
    
    try:
        repositories = get_repositories(org_name)
        total_repos = len(repositories)
        found_tags = []
        
        # Create regex pattern for version matching
        escaped_pattern = re.escape(version_pattern)
        regex_patterns = [
            rf"^{escaped_pattern}\.",  # 0.75.x
            rf"^v{escaped_pattern}\.",  # v0.75.x
            rf"^{escaped_pattern}$",    # exact match
            rf"^v{escaped_pattern}$"    # exact match with v
        ]
        
        for repo in repositories:
            repo_name = repo.get('name', '')
            repo_url = repo.get('url', '')
            
            if not repo_name or len(found_tags) >= max_results:
                continue
                
            tags = get_repository_tags(org_name, repo_name)
            
            for tag in tags[:10]:  # Limit to first 10 tags per repo
                if len(found_tags) >= max_results:
                    break
                    
                # Check if tag matches any of our patterns
                if any(re.match(pattern, tag) for pattern in regex_patterns):
                    commit_info = get_tag_commit_info(org_name, repo_name, tag)
                    
                    tag_info = TagInfo(
                        tag_name=tag,
                        commit_id=commit_info.get('commit_sha', '') if commit_info else '',
                        author=commit_info.get('author') if commit_info else None,
                        date=commit_info.get('date') if commit_info else None,
                        message=commit_info.get('message') if commit_info else None,
                        repository_name=repo_name,
                        repository_url=repo_url,
                        tag_url=f"{repo_url}/releases/tag/{tag}"
                    )
                    found_tags.append(tag_info)
        
        duration = (datetime.now() - start_time).total_seconds()
        
        return ScanResult(
            total_repositories_scanned=total_repos,
            repositories_with_tag=len(set(tag.repository_name for tag in found_tags)),
            tags_found=found_tags,
            scan_timestamp=start_time.isoformat(),
            scan_duration_seconds=duration
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Pattern scan failed: {str(e)}")

# Error handlers
@app.exception_handler(404)
async def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content=ErrorResponse(
            error="Not Found",
            details="The requested endpoint was not found"
        ).dict()
    )

@app.exception_handler(500)
async def internal_error_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content=ErrorResponse(
            error="Internal Server Error",
            details="An unexpected error occurred"
        ).dict()
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

