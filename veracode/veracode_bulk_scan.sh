#!/bin/bash

# Veracode Bulk Scan Script
# This script runs Veracode scans for multiple applications from a configuration file

set -e

# Check required environment variables
if [[ -z "$VERACODE_API_ID" || -z "$VERACODE_API_KEY" ]]; then
    echo "Error: VERACODE_API_ID and VERACODE_API_KEY environment variables must be set"
    exit 1
fi

# Default values
CONFIG_FILE=""
LOG_DIR="./logs"

# Function to display usage
usage() {
    echo "Usage: $0 -c <config_file> [-l <log_directory>]"
    echo "  -c: Configuration file with scan details"
    echo "  -l: Log directory (default: ./logs)"
    echo "  -h: Display this help message"
    echo ""
    echo "Config file format (CSV):"
    echo "app_name,version,filepath"
    echo "MyApp1,1.0.0,/path/to/app1"
    echo "MyApp2,2.0.0,/path/to/app2"
    exit 1
}

# Parse command line arguments
while getopts "c:l:h" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        l) LOG_DIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate required parameters
if [[ -z "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file (-c) is required"
    usage
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file '$CONFIG_FILE' does not exist"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "Starting Veracode bulk scan..."
echo "Configuration file: $CONFIG_FILE"
echo "Log directory: $LOG_DIR"

# Read configuration file and process each line
line_number=0
success_count=0
error_count=0

while IFS=',' read -r app_name version filepath || [[ -n "$app_name" ]]; do
    line_number=$((line_number + 1))
    
    # Skip header line and empty lines
    if [[ $line_number -eq 1 ]] || [[ -z "$app_name" ]]; then
        continue
    fi
    
    # Trim whitespace
    app_name=$(echo "$app_name" | xargs)
    version=$(echo "$version" | xargs)
    filepath=$(echo "$filepath" | xargs)
    
    echo "Processing: $app_name v$version from $filepath"
    
    # Create individual log file
    log_file="$LOG_DIR/${app_name}_${version}_$(date +%Y%m%d_%H%M%S).log"
    
    # Check if file/directory exists
    if [[ ! -e "$filepath" ]]; then
        echo "Error: File or directory '$filepath' does not exist for $app_name" | tee -a "$log_file"
        error_count=$((error_count + 1))
        continue
    fi
    
    # Run individual scan (you would replace this with actual Veracode scan command)
    if ./run_single_scan.sh -a "$app_name" -v "$version" -f "$filepath" &>> "$log_file"; then
        echo "✓ Successfully initiated scan for $app_name v$version"
        success_count=$((success_count + 1))
    else
        echo "✗ Failed to initiate scan for $app_name v$version"
        error_count=$((error_count + 1))
    fi
    
    # Add delay between scans to avoid rate limiting
    sleep 2
    
done < "$CONFIG_FILE"

echo ""
echo "Bulk scan completed!"
echo "Successfully processed: $success_count applications"
echo "Errors encountered: $error_count applications"
echo "Check individual log files in $LOG_DIR for details"
