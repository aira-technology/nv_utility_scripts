#!/usr/bin/env python3
"""
Data Transformer for Repository Tag Scanner

Converts API scan results into structured storage format for UI consumption.
This script can be used to transform the output from our REST API or shell scripts
into a standardized JSON format that UIs can easily consume.
"""

import json
import argparse
from datetime import datetime
from typing import Dict, List, Any, Optional
from collections import defaultdict
import requests
from pathlib import Path


class VersionTagTransformer:
    """Transforms version tag scan results into structured storage format"""
    
    def __init__(self, schema_version: str = "1.0.0"):
        self.schema_version = schema_version
    
    def transform_api_response(self, api_response: Dict[str, Any], 
                             organization: str = None, 
                             scan_type: str = "specific_tag") -> Dict[str, Any]:
        """Transform REST API response to storage format"""
        
        # Extract metadata
        metadata = {
            "last_updated": datetime.now().isoformat() + "Z",
            "scan_duration_seconds": api_response.get("scan_duration_seconds", 0),
            "organization": organization or "unknown",
            "total_repositories_scanned": api_response.get("total_repositories_scanned", 0),
            "scan_type": scan_type,
            "version": self.schema_version
        }
        
        # Process tags
        tags_dict = {}
        tags_found = api_response.get("tags_found", [])
        
        # Group by tag name
        tag_groups = defaultdict(list)
        for tag_info in tags_found:
            tag_name = tag_info.get("tag_name", "unknown")
            tag_groups[tag_name].append(tag_info)
        
        # Transform each tag group
        for tag_name, repositories in tag_groups.items():
            transformed_repos = []
            
            for repo in repositories:
                commit_id = repo.get("commit_id", "")
                transformed_repo = {
                    "repository_name": repo.get("repository_name", ""),
                    "commit_id": commit_id,
                    "commit_short": commit_id[:7] if commit_id else "",
                    "author": repo.get("author", ""),
                    "author_email": self._extract_email_from_author(repo.get("author", "")),
                    "date": repo.get("date", ""),
                    "message": repo.get("message", ""),
                    "repository_url": repo.get("repository_url", ""),
                    "tag_url": repo.get("tag_url", ""),
                    "deployment_status": "unknown",  # Default, can be updated later
                    "environment": "unknown",      # Default, can be updated later
                    "repository_path": repo.get("repository_path")
                }
                transformed_repos.append(transformed_repo)
            
            # Create summary
            dates = [repo.get("date", "") for repo in transformed_repos if repo.get("date")]
            latest_date = max(dates) if dates else ""
            
            # Extract unique environments (filter out 'unknown')
            environments = list(set(
                repo["environment"] for repo in transformed_repos 
                if repo["environment"] != "unknown"
            ))
            
            tags_dict[tag_name] = {
                "tag_name": tag_name,
                "repositories": transformed_repos,
                "summary": {
                    "total_repositories": len(transformed_repos),
                    "latest_commit_date": latest_date,
                    "deployment_environments": environments
                }
            }
        
        # Calculate statistics
        all_repos = [repo for tag_data in tags_dict.values() for repo in tag_data["repositories"]]
        unique_repos = set(repo["repository_name"] for repo in all_repos)
        
        # Find most common tag
        tag_counts = {tag: data["summary"]["total_repositories"] for tag, data in tags_dict.items()}
        most_common_tag = max(tag_counts, key=tag_counts.get) if tag_counts else ""
        
        # Find latest tag date
        all_dates = []
        for tag_data in tags_dict.values():
            if tag_data["summary"]["latest_commit_date"]:
                all_dates.append(tag_data["summary"]["latest_commit_date"])
        latest_tag_date = max(all_dates) if all_dates else ""
        
        statistics = {
            "total_unique_tags": len(tags_dict),
            "total_repositories_with_tags": len(unique_repos),
            "most_common_tag": most_common_tag,
            "latest_tag_date": latest_tag_date
        }
        
        return {
            "metadata": metadata,
            "tags": tags_dict,
            "statistics": statistics
        }
    
    def _extract_email_from_author(self, author: str) -> Optional[str]:
        """Extract email from author string if present"""
        if "<" in author and ">" in author:
            start = author.find("<") + 1
            end = author.find(">")
            return author[start:end] if start < end else None
        return None
    
    def enhance_with_deployment_info(self, data: Dict[str, Any], 
                                   deployment_config: Dict[str, Any]) -> Dict[str, Any]:
        """Enhance data with deployment status and environment information"""
        
        for tag_name, tag_data in data["tags"].items():
            for repo in tag_data["repositories"]:
                repo_name = repo["repository_name"]
                
                # Check deployment config for this repository
                if repo_name in deployment_config:
                    repo_config = deployment_config[repo_name]
                    
                    # Update deployment status and environment
                    if tag_name in repo_config.get("deployed_versions", {}):
                        version_info = repo_config["deployed_versions"][tag_name]
                        repo["deployment_status"] = version_info.get("status", "unknown")
                        repo["environment"] = version_info.get("environment", "unknown")
                    else:
                        repo["deployment_status"] = "not_deployed"
                        repo["environment"] = "none"
        
        # Recalculate summary deployment environments
        for tag_name, tag_data in data["tags"].items():
            environments = list(set(
                repo["environment"] for repo in tag_data["repositories"]
                if repo["environment"] not in ["unknown", "none"]
            ))
            tag_data["summary"]["deployment_environments"] = environments
        
        return data
    
    def save_to_file(self, data: Dict[str, Any], file_path: str, 
                     pretty: bool = True) -> None:
        """Save transformed data to JSON file"""
        path = Path(file_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(file_path, 'w') as f:
            if pretty:
                json.dump(data, f, indent=2, ensure_ascii=False)
            else:
                json.dump(data, f, separators=(',', ':'), ensure_ascii=False)
    
    def load_from_file(self, file_path: str) -> Dict[str, Any]:
        """Load data from JSON file"""
        with open(file_path, 'r') as f:
            return json.load(f)
    
    def merge_scan_results(self, existing_data: Dict[str, Any], 
                          new_data: Dict[str, Any]) -> Dict[str, Any]:
        """Merge new scan results with existing data"""
        
        # Update metadata with latest scan info
        merged_data = existing_data.copy()
        merged_data["metadata"] = new_data["metadata"]
        
        # Merge tags - new data overwrites existing for same tag names
        merged_data["tags"].update(new_data["tags"])
        
        # Recalculate statistics
        all_repos = [repo for tag_data in merged_data["tags"].values() 
                    for repo in tag_data["repositories"]]
        unique_repos = set(repo["repository_name"] for repo in all_repos)
        
        tag_counts = {tag: data["summary"]["total_repositories"] 
                     for tag, data in merged_data["tags"].items()}
        most_common_tag = max(tag_counts, key=tag_counts.get) if tag_counts else ""
        
        all_dates = []
        for tag_data in merged_data["tags"].values():
            if tag_data["summary"]["latest_commit_date"]:
                all_dates.append(tag_data["summary"]["latest_commit_date"])
        latest_tag_date = max(all_dates) if all_dates else ""
        
        merged_data["statistics"] = {
            "total_unique_tags": len(merged_data["tags"]),
            "total_repositories_with_tags": len(unique_repos),
            "most_common_tag": most_common_tag,
            "latest_tag_date": latest_tag_date
        }
        
        return merged_data


def fetch_from_api(api_url: str, organization: str, tag: str) -> Dict[str, Any]:
    """Fetch data from REST API"""
    url = f"{api_url}/api/v1/scan/organization/{organization}/tag/{tag}"
    response = requests.get(url, timeout=120)
    response.raise_for_status()
    return response.json()


def main():
    parser = argparse.ArgumentParser(description="Transform repository tag scan results")
    parser.add_argument("--api-url", default="http://localhost:8000", 
                       help="Base URL of the REST API")
    parser.add_argument("--organization", default="aira-technology",
                       help="GitHub organization name")
    parser.add_argument("--tag", default="0.75.5",
                       help="Tag version to scan for")
    parser.add_argument("--input-file", 
                       help="Input JSON file (API response format)")
    parser.add_argument("--output-file", default="data/version_tags.json",
                       help="Output file path")
    parser.add_argument("--deployment-config", 
                       help="Deployment configuration file")
    parser.add_argument("--merge-existing", action="store_true",
                       help="Merge with existing data file")
    parser.add_argument("--pretty", action="store_true", default=True,
                       help="Pretty print JSON output")
    
    args = parser.parse_args()
    
    transformer = VersionTagTransformer()
    
    # Get data either from API or file
    if args.input_file:
        print(f"Reading data from file: {args.input_file}")
        with open(args.input_file, 'r') as f:
            api_response = json.load(f)
    else:
        print(f"Fetching data from API: {args.api_url}")
        api_response = fetch_from_api(args.api_url, args.organization, args.tag)
    
    # Transform the data
    print("Transforming data...")
    transformed_data = transformer.transform_api_response(
        api_response, args.organization, "specific_tag"
    )
    
    # Load deployment configuration if provided
    if args.deployment_config:
        print(f"Loading deployment configuration: {args.deployment_config}")
        with open(args.deployment_config, 'r') as f:
            deployment_config = json.load(f)
        transformed_data = transformer.enhance_with_deployment_info(
            transformed_data, deployment_config
        )
    
    # Merge with existing data if requested
    if args.merge_existing and Path(args.output_file).exists():
        print(f"Merging with existing data: {args.output_file}")
        existing_data = transformer.load_from_file(args.output_file)
        transformed_data = transformer.merge_scan_results(existing_data, transformed_data)
    
    # Save the transformed data
    print(f"Saving transformed data to: {args.output_file}")
    transformer.save_to_file(transformed_data, args.output_file, args.pretty)
    
    # Print summary
    stats = transformed_data["statistics"]
    print(f"\n✅ Transformation complete!")
    print(f"📊 Summary:")
    print(f"   - Unique tags: {stats['total_unique_tags']}")
    print(f"   - Repositories with tags: {stats['total_repositories_with_tags']}")
    print(f"   - Most common tag: {stats['most_common_tag']}")
    print(f"   - Latest tag date: {stats['latest_tag_date']}")
    print(f"📁 Data saved to: {args.output_file}")


if __name__ == "__main__":
    main()

