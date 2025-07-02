#!/usr/bin/env python3

"""
Veracode Repository Status Checker
This script checks the status of all Veracode scans for repositories
"""

import os
import sys
import json
import time
import requests
from typing import Dict, List, Optional
import argparse
from datetime import datetime


class VeracodeStatusChecker:
    def __init__(self, api_id: str, api_key: str):
        """Initialize Veracode status checker with API credentials"""
        self.api_id = api_id
        self.api_key = api_key
        self.base_url = "https://api.veracode.com/appsec/v1"
        self.session = requests.Session()
        
    def get_applications(self) -> List[Dict]:
        """Get list of all applications from Veracode"""
        try:
            # This is a placeholder - you would implement actual Veracode API calls
            # using their authentication mechanism (HMAC or OAuth)
            
            # Example structure of what this would return:
            applications = [
                {
                    "id": "12345",
                    "name": "MyApp1",
                    "last_scan_date": "2024-01-15T10:30:00Z",
                    "status": "Completed",
                    "findings_count": 5
                },
                {
                    "id": "12346", 
                    "name": "MyApp2",
                    "last_scan_date": "2024-01-14T15:45:00Z",
                    "status": "In Progress",
                    "findings_count": None
                }
            ]
            
            print(f"Retrieved {len(applications)} applications from Veracode")
            return applications
            
        except Exception as e:
            print(f"Error retrieving applications: {str(e)}")
            return []
    
    def get_scan_status(self, app_id: str) -> Optional[Dict]:
        """Get detailed scan status for a specific application"""
        try:
            # Placeholder for actual API call
            # You would implement the actual Veracode API call here
            
            status_info = {
                "app_id": app_id,
                "scan_status": "Completed",
                "last_updated": datetime.now().isoformat(),
                "findings": {
                    "critical": 2,
                    "high": 3,
                    "medium": 8,
                    "low": 12,
                    "informational": 5
                },
                "compliance_status": "Non-Compliant"
            }
            
            return status_info
            
        except Exception as e:
            print(f"Error getting scan status for app {app_id}: {str(e)}")
            return None
    
    def check_all_repos_status(self, output_format: str = "table") -> None:
        """Check status of all repositories and display results"""
        print("Checking status of all Veracode scans...")
        print("=" * 80)
        
        applications = self.get_applications()
        
        if not applications:
            print("No applications found or error retrieving data")
            return
        
        all_status = []
        
        for app in applications:
            app_status = self.get_scan_status(app["id"])
            if app_status:
                combined_status = {**app, **app_status}
                all_status.append(combined_status)
        
        if output_format.lower() == "json":
            self._output_json(all_status)
        elif output_format.lower() == "csv":
            self._output_csv(all_status)
        else:
            self._output_table(all_status)
    
    def _output_table(self, status_data: List[Dict]) -> None:
        """Output status in table format"""
        print(f"{'Application Name':<20} {'Status':<15} {'Last Scan':<20} {'Findings':<10} {'Compliance':<15}")
        print("-" * 80)
        
        for app in status_data:
            name = app.get("name", "Unknown")[:19]
            status = app.get("scan_status", "Unknown")[:14]
            last_scan = app.get("last_scan_date", "Never")[:19]
            
            findings = app.get("findings", {})
            if findings:
                total_findings = sum([
                    findings.get("critical", 0),
                    findings.get("high", 0),
                    findings.get("medium", 0),
                    findings.get("low", 0)
                ])
                findings_str = str(total_findings)
            else:
                findings_str = "N/A"
            
            compliance = app.get("compliance_status", "Unknown")[:14]
            
            print(f"{name:<20} {status:<15} {last_scan:<20} {findings_str:<10} {compliance:<15}")
    
    def _output_json(self, status_data: List[Dict]) -> None:
        """Output status in JSON format"""
        print(json.dumps(status_data, indent=2, default=str))
    
    def _output_csv(self, status_data: List[Dict]) -> None:
        """Output status in CSV format"""
        print("Application Name,Status,Last Scan Date,Critical,High,Medium,Low,Compliance Status")
        
        for app in status_data:
            name = app.get("name", "Unknown")
            status = app.get("scan_status", "Unknown")
            last_scan = app.get("last_scan_date", "Never")
            compliance = app.get("compliance_status", "Unknown")
            
            findings = app.get("findings", {})
            critical = findings.get("critical", 0)
            high = findings.get("high", 0)
            medium = findings.get("medium", 0)
            low = findings.get("low", 0)
            
            print(f"{name},{status},{last_scan},{critical},{high},{medium},{low},{compliance}")


def main():
    parser = argparse.ArgumentParser(description="Check Veracode scan status for all repositories")
    parser.add_argument("--format", "-f", choices=["table", "json", "csv"], 
                       default="table", help="Output format (default: table)")
    parser.add_argument("--config", "-c", help="Path to configuration file")
    
    args = parser.parse_args()
    
    # Get API credentials from environment variables
    api_id = os.getenv("VERACODE_API_ID")
    api_key = os.getenv("VERACODE_API_KEY")
    
    if not api_id or not api_key:
        print("Error: VERACODE_API_ID and VERACODE_API_KEY environment variables must be set")
        sys.exit(1)
    
    # Initialize checker and run
    checker = VeracodeStatusChecker(api_id, api_key)
    checker.check_all_repos_status(output_format=args.format)


if __name__ == "__main__":
    main()
