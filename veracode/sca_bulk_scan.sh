#!/bin/bash

# Veracode SCA Bulk Scan Script
# This script runs SCA scans for multiple projects from a configuration file

set -e

# Check required environment variables
if [[ -z "$VERACODE_API_ID" || -z "$VERACODE_API_KEY" ]]; then
    echo "Error: VERACODE_API_ID and VERACODE_API_KEY environment variables must be set"
    exit 1
fi

# Default values
CONFIG_FILE=""
LOG_DIR="./sca_logs"
RESULTS_DIR="./sca_results"
SCAN_TYPE="default"
OUTPUT_FORMAT="json"
PARALLEL_SCANS=1

# Function to display usage
usage() {
    echo "Usage: $0 -c <config_file> [OPTIONS]"
    echo ""
    echo "Required Parameters:"
    echo "  -c: Configuration file with project details"
    echo ""
    echo "Optional Parameters:"
    echo "  -l: Log directory (default: ./sca_logs)"
    echo "  -r: Results directory (default: ./sca_results)"
    echo "  -t: Scan type for all projects (default, quick, deep) - default: default"
    echo "  -f: Output format (table, json, xml) - default: json"
    echo "  -p: Number of parallel scans (default: 1)"
    echo "  -h: Display this help message"
    echo ""
    echo "Config file format (CSV):"
    echo "project_name,project_path,scan_type,include_dev_deps,workspace_id"
    echo "WebApp,/path/to/webapp,default,false,"
    echo "APIService,/path/to/api,deep,true,workspace123"
    echo "MobileApp,/path/to/mobile,quick,false,"
    echo ""
    echo "Note: scan_type, include_dev_deps, and workspace_id are optional in config"
    exit 1
}

# Parse command line arguments
while getopts "c:l:r:t:f:p:h" opt; do
    case $opt in
        c) CONFIG_FILE="$OPTARG" ;;
        l) LOG_DIR="$OPTARG" ;;
        r) RESULTS_DIR="$OPTARG" ;;
        t) SCAN_TYPE="$OPTARG" ;;
        f) OUTPUT_FORMAT="$OPTARG" ;;
        p) PARALLEL_SCANS="$OPTARG" ;;
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

# Validate parallel scans number
if ! [[ "$PARALLEL_SCANS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Parallel scans must be a positive integer"
    exit 1
fi

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$RESULTS_DIR"

echo "Starting Veracode SCA bulk scan..."
echo "Configuration file: $CONFIG_FILE"
echo "Log directory: $LOG_DIR"
echo "Results directory: $RESULTS_DIR"
echo "Default scan type: $SCAN_TYPE"
echo "Default output format: $OUTPUT_FORMAT"
echo "Parallel scans: $PARALLEL_SCANS"
echo ""

# Function to run a single SCA scan
run_single_sca_scan() {
    local project_name="$1"
    local project_path="$2"
    local scan_type="$3"
    local include_dev_deps="$4"
    local workspace_id="$5"
    local log_file="$6"
    
    echo "Starting SCA scan for: $project_name" | tee -a "$log_file"
    
    # Build command
    local cmd="./run_sca_scan.sh -p \"$project_name\" -d \"$project_path\""
    
    if [[ -n "$scan_type" && "$scan_type" != "default" ]]; then
        cmd="$cmd -t $scan_type"
    fi
    
    cmd="$cmd -f $OUTPUT_FORMAT"
    
    if [[ -n "$include_dev_deps" && "$include_dev_deps" == "true" ]]; then
        cmd="$cmd -i true"
    fi
    
    if [[ -n "$workspace_id" ]]; then
        cmd="$cmd -w $workspace_id"
    fi
    
    echo "Command: $cmd" | tee -a "$log_file"
    
    # Execute the scan
    if eval "$cmd" >> "$log_file" 2>&1; then
        echo "✓ Successfully completed SCA scan for $project_name" | tee -a "$log_file"
        return 0
    else
        echo "✗ Failed SCA scan for $project_name" | tee -a "$log_file"
        return 1
    fi
}

# Read configuration file and validate
line_number=0
total_projects=0
valid_projects=0

echo "Validating configuration file..."
while IFS=',' read -r project_name project_path scan_type include_dev_deps workspace_id || [[ -n "$project_name" ]]; do
    line_number=$((line_number + 1))
    
    # Skip header line and empty lines
    if [[ $line_number -eq 1 ]] || [[ -z "$project_name" ]]; then
        continue
    fi
    
    total_projects=$((total_projects + 1))
    
    # Trim whitespace
    project_name=$(echo "$project_name" | xargs)
    project_path=$(echo "$project_path" | xargs)
    scan_type=$(echo "$scan_type" | xargs)
    include_dev_deps=$(echo "$include_dev_deps" | xargs)
    workspace_id=$(echo "$workspace_id" | xargs)
    
    # Validate project directory exists
    if [[ ! -d "$project_path" ]]; then
        echo "⚠ Warning: Project directory '$project_path' for '$project_name' does not exist"
        continue
    fi
    
    valid_projects=$((valid_projects + 1))
    echo "✓ Validated: $project_name at $project_path"
    
done < "$CONFIG_FILE"

echo ""
echo "Validation complete:"
echo "Total projects in config: $total_projects"
echo "Valid projects: $valid_projects"
echo "Invalid projects: $((total_projects - valid_projects))"

if [[ $valid_projects -eq 0 ]]; then
    echo "Error: No valid projects found in configuration file"
    exit 1
fi

echo ""
echo "Starting bulk SCA scans..."

# Create master log file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MASTER_LOG="$LOG_DIR/bulk_sca_scan_${TIMESTAMP}.log"
echo "Bulk SCA Scan Started: $(date)" > "$MASTER_LOG"

# Process each project
line_number=0
success_count=0
error_count=0
skipped_count=0

# Create array to hold background job PIDs if running parallel scans
declare -a job_pids=()

while IFS=',' read -r project_name project_path scan_type include_dev_deps workspace_id || [[ -n "$project_name" ]]; do
    line_number=$((line_number + 1))
    
    # Skip header line and empty lines
    if [[ $line_number -eq 1 ]] || [[ -z "$project_name" ]]; then
        continue
    fi
    
    # Trim whitespace
    project_name=$(echo "$project_name" | xargs)
    project_path=$(echo "$project_path" | xargs)
    scan_type=$(echo "$scan_type" | xargs)
    include_dev_deps=$(echo "$include_dev_deps" | xargs)
    workspace_id=$(echo "$workspace_id" | xargs)
    
    # Skip if directory doesn't exist
    if [[ ! -d "$project_path" ]]; then
        echo "Skipping $project_name: directory not found"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    # Use default scan type if not specified
    if [[ -z "$scan_type" ]]; then
        scan_type="$SCAN_TYPE"
    fi
    
    # Create individual log file
    individual_log="$LOG_DIR/${project_name}_sca_${TIMESTAMP}.log"
    
    echo "Processing: $project_name ($scan_type scan)" | tee -a "$MASTER_LOG"
    
    if [[ $PARALLEL_SCANS -eq 1 ]]; then
        # Sequential execution
        if run_single_sca_scan "$project_name" "$project_path" "$scan_type" "$include_dev_deps" "$workspace_id" "$individual_log"; then
            success_count=$((success_count + 1))
            echo "✓ $project_name completed successfully" | tee -a "$MASTER_LOG"
        else
            error_count=$((error_count + 1))
            echo "✗ $project_name failed" | tee -a "$MASTER_LOG"
        fi
        
        # Add delay between scans to avoid rate limiting
        sleep 3
    else
        # Parallel execution
        run_single_sca_scan "$project_name" "$project_path" "$scan_type" "$include_dev_deps" "$workspace_id" "$individual_log" &
        job_pids+=($!)
        
        # If we've reached the parallel limit, wait for jobs to complete
        if [[ ${#job_pids[@]} -ge $PARALLEL_SCANS ]]; then
            for pid in "${job_pids[@]}"; do
                if wait "$pid"; then
                    success_count=$((success_count + 1))
                else
                    error_count=$((error_count + 1))
                fi
            done
            job_pids=()
        fi
    fi
    
done < "$CONFIG_FILE"

# Wait for any remaining parallel jobs
if [[ $PARALLEL_SCANS -gt 1 && ${#job_pids[@]} -gt 0 ]]; then
    echo "Waiting for remaining scans to complete..."
    for pid in "${job_pids[@]}"; do
        if wait "$pid"; then
            success_count=$((success_count + 1))
        else
            error_count=$((error_count + 1))
        fi
    done
fi

# Generate final report
echo ""
echo "=== BULK SCA SCAN COMPLETED ==="
echo "Timestamp: $(date)"
echo "Total projects processed: $((success_count + error_count))"
echo "Successfully scanned: $success_count"
echo "Failed scans: $error_count"
echo "Skipped projects: $skipped_count"
echo ""
echo "Results saved to: $RESULTS_DIR"
echo "Logs saved to: $LOG_DIR"
echo "Master log: $MASTER_LOG"

# Write summary to master log
{
    echo ""
    echo "=== FINAL SUMMARY ==="
    echo "Bulk SCA Scan Completed: $(date)"
    echo "Total projects processed: $((success_count + error_count))"
    echo "Successfully scanned: $success_count"
    echo "Failed scans: $error_count"
    echo "Skipped projects: $skipped_count"
} >> "$MASTER_LOG"

echo ""
echo "Next steps:"
echo "1. Review individual scan results in $RESULTS_DIR"
echo "2. Check logs for any failed scans in $LOG_DIR"
echo "3. Address high-severity vulnerabilities found"
echo "4. Update vulnerable dependencies across projects"
