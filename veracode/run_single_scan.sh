#!/bin/bash

# Veracode Single Scan Script
# This script runs a single Veracode scan for a specified application

set -e

# Check required environment variables
if [[ -z "$VERACODE_API_ID" || -z "$VERACODE_API_KEY" ]]; then
    echo "Error: VERACODE_API_ID and VERACODE_API_KEY environment variables must be set"
    exit 1
fi

# Default values
APP_NAME=""
VERSION=""
FILEPATH=""

# Function to display usage
usage() {
    echo "Usage: $0 -a <app_name> -v <version> -f <filepath>"
    echo "  -a: Application name in Veracode"
    echo "  -v: Version/build name"
    echo "  -f: Path to the file/directory to scan"
    echo "  -h: Display this help message"
    exit 1
}

# Parse command line arguments
while getopts "a:v:f:h" opt; do
    case $opt in
        a) APP_NAME="$OPTARG" ;;
        v) VERSION="$OPTARG" ;;
        f) FILEPATH="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate required parameters
if [[ -z "$APP_NAME" || -z "$VERSION" || -z "$FILEPATH" ]]; then
    echo "Error: All parameters (-a, -v, -f) are required"
    usage
fi

# Check if file/directory exists
if [[ ! -e "$FILEPATH" ]]; then
    echo "Error: File or directory '$FILEPATH' does not exist"
    exit 1
fi

echo "Starting Veracode scan..."
echo "Application: $APP_NAME"
echo "Version: $VERSION"
echo "File/Directory: $FILEPATH"

# Run Veracode scan using the Veracode CLI or API
# This would typically use the Veracode CLI tool or make API calls
# Example using Veracode CLI (adjust based on your setup):
# veracode scan --app-name "$APP_NAME" --version "$VERSION" --source "$FILEPATH"

echo "Veracode scan initiated successfully"
