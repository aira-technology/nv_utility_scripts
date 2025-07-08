#!/bin/bash

# Veracode Software Composition Analysis (SCA) Scan Script
# This script runs SCA scans to identify open source vulnerabilities

set -e

# Check required environment variables
if [[ -z "$VERACODE_API_ID" || -z "$VERACODE_API_KEY" ]]; then
    echo "Error: VERACODE_API_ID and VERACODE_API_KEY environment variables must be set"
    exit 1
fi

# Default values
PROJECT_NAME=""
PROJECT_PATH=""
SCAN_TYPE="default"
OUTPUT_FORMAT="table"
WORKSPACE_ID=""
INCLUDE_DEV_DEPS="false"

# Function to display usage
usage() {
    echo "Usage: $0 -p <project_name> -d <project_path> [OPTIONS]"
    echo ""
    echo "Required Parameters:"
    echo "  -p: Project name in Veracode SCA"
    echo "  -d: Path to project directory (containing package files)"
    echo ""
    echo "Optional Parameters:"
    echo "  -t: Scan type (default, quick, deep) - default: default"
    echo "  -f: Output format (table, json, xml) - default: table"
    echo "  -w: Workspace ID (if using workspaces)"
    echo "  -i: Include dev dependencies (true/false) - default: false"
    echo "  -h: Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -p \"MyWebApp\" -d \"/path/to/project\""
    echo "  $0 -p \"APIService\" -d \"./api-service\" -t deep -f json"
    echo "  $0 -p \"Frontend\" -d \"./frontend\" -i true"
    exit 1
}

# Parse command line arguments
while getopts "p:d:t:f:w:i:h" opt; do
    case $opt in
        p) PROJECT_NAME="$OPTARG" ;;
        d) PROJECT_PATH="$OPTARG" ;;
        t) SCAN_TYPE="$OPTARG" ;;
        f) OUTPUT_FORMAT="$OPTARG" ;;
        w) WORKSPACE_ID="$OPTARG" ;;
        i) INCLUDE_DEV_DEPS="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_NAME" || -z "$PROJECT_PATH" ]]; then
    echo "Error: Project name (-p) and project path (-d) are required"
    usage
fi

# Check if project directory exists
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Error: Project directory '$PROJECT_PATH' does not exist"
    exit 1
fi

# Validate scan type
if [[ ! "$SCAN_TYPE" =~ ^(default|quick|deep)$ ]]; then
    echo "Error: Invalid scan type. Must be 'default', 'quick', or 'deep'"
    exit 1
fi

# Validate output format
if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json|xml)$ ]]; then
    echo "Error: Invalid output format. Must be 'table', 'json', or 'xml'"
    exit 1
fi

echo "Starting Veracode SCA scan..."
echo "Project: $PROJECT_NAME"
echo "Path: $PROJECT_PATH"
echo "Scan Type: $SCAN_TYPE"
echo "Output Format: $OUTPUT_FORMAT"
echo "Include Dev Dependencies: $INCLUDE_DEV_DEPS"
[[ -n "$WORKSPACE_ID" ]] && echo "Workspace ID: $WORKSPACE_ID"

# Check for common package files
echo ""
echo "Detecting package managers..."
PACKAGE_FILES_FOUND=false

if [[ -f "$PROJECT_PATH/package.json" ]]; then
    echo "✓ Found package.json (Node.js/npm)"
    PACKAGE_FILES_FOUND=true
fi

if [[ -f "$PROJECT_PATH/requirements.txt" || -f "$PROJECT_PATH/Pipfile" || -f "$PROJECT_PATH/poetry.lock" ]]; then
    echo "✓ Found Python dependencies"
    PACKAGE_FILES_FOUND=true
fi

if [[ -f "$PROJECT_PATH/pom.xml" || -f "$PROJECT_PATH/build.gradle" ]]; then
    echo "✓ Found Java dependencies"
    PACKAGE_FILES_FOUND=true
fi

if [[ -f "$PROJECT_PATH/Gemfile" ]]; then
    echo "✓ Found Gemfile (Ruby)"
    PACKAGE_FILES_FOUND=true
fi

if [[ -f "$PROJECT_PATH/composer.json" ]]; then
    echo "✓ Found composer.json (PHP)"
    PACKAGE_FILES_FOUND=true
fi

if [[ -f "$PROJECT_PATH/go.mod" ]]; then
    echo "✓ Found go.mod (Go)"
    PACKAGE_FILES_FOUND=true
fi

if [[ -f "$PROJECT_PATH/Cargo.toml" ]]; then
    echo "✓ Found Cargo.toml (Rust)"
    PACKAGE_FILES_FOUND=true
fi

if [[ "$PACKAGE_FILES_FOUND" == "false" ]]; then
    echo "⚠ Warning: No common package files detected. SCA scan may not find dependencies."
    echo "  Common files include: package.json, requirements.txt, pom.xml, Gemfile, etc."
fi

echo ""
echo "Initiating SCA scan..."

# Create timestamped results directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="./sca_results_${PROJECT_NAME}_${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Build SCA command based on parameters
SCA_CMD="srcclr scan"

# Add project path
SCA_CMD="$SCA_CMD --url $PROJECT_PATH"

# Add scan type options
case $SCAN_TYPE in
    "quick")
        SCA_CMD="$SCA_CMD --quick"
        ;;
    "deep")
        SCA_CMD="$SCA_CMD --recursive"
        ;;
esac

# Add dev dependencies flag
if [[ "$INCLUDE_DEV_DEPS" == "true" ]]; then
    SCA_CMD="$SCA_CMD --allow-dirty"
fi

# Add output format
case $OUTPUT_FORMAT in
    "json")
        SCA_CMD="$SCA_CMD --json=$RESULTS_DIR/sca_results.json"
        ;;
    "xml")
        SCA_CMD="$SCA_CMD --xml=$RESULTS_DIR/sca_results.xml"
        ;;
esac

# Add workspace if specified
if [[ -n "$WORKSPACE_ID" ]]; then
    SCA_CMD="$SCA_CMD --workspace-id=$WORKSPACE_ID"
fi

echo "Command: $SCA_CMD"
echo ""

# Execute the scan
if eval "$SCA_CMD" 2>&1 | tee "$RESULTS_DIR/scan_log.txt"; then
    echo ""
    echo "✓ SCA scan completed successfully!"
    echo "Results saved to: $RESULTS_DIR"
    
    # Generate summary report
    echo ""
    echo "=== SCAN SUMMARY ==="
    echo "Project: $PROJECT_NAME"
    echo "Scan Type: $SCAN_TYPE"
    echo "Timestamp: $(date)"
    echo "Results Directory: $RESULTS_DIR"
    
    # Check if results files exist and show basic info
    if [[ -f "$RESULTS_DIR/sca_results.json" ]]; then
        echo "JSON Results: $RESULTS_DIR/sca_results.json"
    fi
    
    if [[ -f "$RESULTS_DIR/sca_results.xml" ]]; then
        echo "XML Results: $RESULTS_DIR/sca_results.xml"
    fi
    
    echo "Scan Log: $RESULTS_DIR/scan_log.txt"
    
else
    echo ""
    echo "✗ SCA scan failed. Check the log for details:"
    echo "Log file: $RESULTS_DIR/scan_log.txt"
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Review the scan results in $RESULTS_DIR"
echo "2. Check for high-severity vulnerabilities"
echo "3. Update vulnerable dependencies"
echo "4. Run follow-up scans to verify fixes"
