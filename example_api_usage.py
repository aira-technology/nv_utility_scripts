#!/usr/bin/env python3
"""
Example usage of the Repository Tag Scanner REST API

This script demonstrates how to use the API to scan for tags.
Make sure the API server is running first: ./start_api.sh
"""

import requests
import json
from typing import Dict, Any

# API base URL
API_BASE = "http://localhost:8000"

def check_api_health() -> Dict[str, Any]:
    """Check if the API is healthy and ready"""
    try:
        response = requests.get(f"{API_BASE}/api/v1/health", timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ API health check failed: {e}")
        print("💡 Make sure to start the API first: ./start_api.sh")
        return {}

def scan_organization_for_tag(org_name: str, tag_version: str) -> Dict[str, Any]:
    """Scan organization for a specific tag"""
    try:
        url = f"{API_BASE}/api/v1/scan/organization/{org_name}/tag/{tag_version}"
        print(f"🔍 Scanning {org_name} organization for tag {tag_version}...")
        
        response = requests.get(url, timeout=120)  # Allow up to 2 minutes
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Scan failed: {e}")
        return {}

def scan_local_repositories(tag_version: str, base_path: str = ".") -> Dict[str, Any]:
    """Scan local repositories for a tag"""
    try:
        url = f"{API_BASE}/api/v1/scan/local/tag/{tag_version}"
        params = {"base_path": base_path} if base_path != "." else {}
        
        print(f"🔍 Scanning local repositories for tag {tag_version}...")
        response = requests.get(url, params=params, timeout=60)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Local scan failed: {e}")
        return {}

def scan_version_patterns(org_name: str, version_pattern: str, max_results: int = 10) -> Dict[str, Any]:
    """Scan for version patterns"""
    try:
        url = f"{API_BASE}/api/v1/scan/organization/{org_name}/patterns/{version_pattern}"
        params = {"max_results": max_results}
        
        print(f"🔍 Scanning for {version_pattern}.x pattern in {org_name}...")
        response = requests.get(url, params=params, timeout=120)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Pattern scan failed: {e}")
        return {}

def print_results(result: Dict[str, Any], title: str):
    """Pretty print scan results"""
    if not result:
        return
        
    print(f"\n{title}")
    print("=" * len(title))
    print(f"📊 Repositories scanned: {result.get('total_repositories_scanned', 0)}")
    print(f"✅ Repositories with tag: {result.get('repositories_with_tag', 0)}")
    print(f"⏱️  Scan duration: {result.get('scan_duration_seconds', 0):.1f} seconds")
    
    tags_found = result.get('tags_found', [])
    if tags_found:
        print(f"\n🏷️  Found tags:")
        for i, tag in enumerate(tags_found, 1):
            print(f"\n{i}. {tag['repository_name']}")
            print(f"   Tag: {tag['tag_name']}")
            print(f"   Commit: {tag['commit_id'][:12]}...")
            if tag.get('author'):
                print(f"   Author: {tag['author']}")
            if tag.get('date'):
                print(f"   Date: {tag['date'][:10]}")
            print(f"   URL: {tag['tag_url']}")
    else:
        print("\n🚫 No tags found matching the criteria")

def main():
    """Main example function"""
    print("🚀 Repository Tag Scanner API - Example Usage")
    print("=" * 50)
    
    # 1. Health check
    print("\n1️⃣  Checking API health...")
    health = check_api_health()
    if health:
        print(f"✅ API Status: {health.get('status')}")
        print(f"🐙 GitHub CLI: {'✅' if health.get('github_cli_available') else '❌'}")
        print(f"📦 Git: {'✅' if health.get('git_available') else '❌'}")
    else:
        print("❌ API is not available. Please start it first with: ./start_api.sh")
        return
    
    # 2. Scan for specific tag (the one we know exists)
    print("\n2️⃣  Scanning aira-technology for v0.75.5...")
    org_result = scan_organization_for_tag("aira-technology", "0.75.5")
    print_results(org_result, "🏢 Organization Scan Results")
    
    # 3. Scan local repositories
    print("\n3️⃣  Scanning local repositories for v0.75.5...")
    local_result = scan_local_repositories("0.75.5")
    print_results(local_result, "💻 Local Repositories Scan Results")
    
    # 4. Scan for version patterns
    print("\n4️⃣  Scanning for 0.75.x pattern...")
    pattern_result = scan_version_patterns("aira-technology", "0.75", max_results=5)
    print_results(pattern_result, "🎯 Pattern Matching Results")
    
    print("\n🎉 Example completed!")
    print("\n💡 Tips:")
    print("   • View interactive docs: http://localhost:8000/docs")
    print("   • Try different organizations and tags")
    print("   • Use the API in your own applications")
    print("   • Check API_DOCUMENTATION.md for more examples")

if __name__ == "__main__":
    main()

