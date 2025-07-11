#!/bin/bash

# SourceClear (srcclr) Bulk Repository Scanner with Consolidated CSV Report for Aira Repositories
# Uses SSH links, switches to feature/v1.0-release branch, removes Pipfile.lock, commits & pushes, then scans

set -e

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

BASE_DIR="/tmp/version-data"
SCAN_RESULTS_DIR="$BASE_DIR/srcclr-scan-results"
LOG_FILE="$SCAN_RESULTS_DIR/scan-log.txt"

REPOSITORIES=(
    "git@github.com:aira-technology/nv_ai_core.git"
    "git@github.com:aira-technology/nv_agentic_adrca_intent_microservice.git"
    "git@github.com:aira-technology/nv_intent_supervisor_microservice.git"
    "git@github.com:aira-technology/nv_agentic_generic_microservice.git"
    "git@github.com:aira-technology/rapp-packaging.git"
    "git@github.com:aira-technology/nv-gateway-orchestrator.git"
    "git@github.com:aira-technology/bert_retriever.git"
    "git@github.com:aira-technology/nv_ad_rca_microservice.git"
    "git@github.com:aira-technology/data-adapter.git"
    "git@github.com:aira-technology/orchestrator-cron-jobs.git"
    "git@github.com:aira-technology/nv_shared_common.git"
    "git@github.com:aira-technology/nv-shared-data.git"
    "git@github.com:aira-technology/nvk-code-executor.git"
    "git@github.com:aira-technology/automated_script.git"
)

print_status() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }

check_srcclr_setup() {
    print_status "Checking SourceClear (srcclr) CLI setup..."
    command -v srcclr &>/dev/null || { print_error "SourceClear CLI is not installed."; exit 1; }
    print_success "SourceClear CLI found at $(which srcclr)"
}

get_repo_name() { basename "$1" .git; }

clone_and_prepare_repository() {
    local repo_url="$1"
    local repo_name
    repo_name=$(get_repo_name "$repo_url")
    local repo_dir="$BASE_DIR/$repo_name"
    local branch="feature/v1.0-release"

    print_status "Cloning and preparing $repo_name"
    if [[ -d "$repo_dir/.git" ]]; then
        cd "$repo_dir"
        git fetch origin || print_warning "Fetch failed for $repo_name"
    else
        git clone "$repo_url" "$repo_dir" || print_error "Clone failed for $repo_name"
        cd "$repo_dir"
    fi

    if git checkout "$branch" 2>/dev/null; then
        git pull origin "$branch" || print_warning "Pull failed on $branch for $repo_name"
        print_success "Checked out $branch for $repo_name"
    else
        print_warning "$branch not found for $repo_name, staying on current branch"
    fi

    # Remove Pipfile.lock if exists and commit
    if [[ -f "Pipfile.lock" ]]; then
        print_status "Removing Pipfile.lock in $repo_name"
        rm Pipfile.lock
        git add Pipfile.lock
        git commit -m "ci: remove Pipfile.lock before srcclr scan" || print_warning "Nothing to commit in $repo_name"
        git push origin "$branch" || print_warning "Push failed for $repo_name"
    fi
}

run_srcclr_scan() {
    local repo_name="$1"
    local repo_dir="$BASE_DIR/$repo_name"
    local results_dir="$SCAN_RESULTS_DIR/$repo_name"
    mkdir -p "$results_dir"
    local output_file="$results_dir/srcclr-scan.txt"

    print_status "Running SourceClear scan on $repo_name"
    if srcclr scan "$repo_dir" > "$output_file" 2>&1; then
        print_success "SourceClear scan completed for $repo_name"
    else
        print_error "SourceClear scan failed for $repo_name. Check $output_file for details."
    fi
}

generate_summary() {
    local csv_file="$SCAN_RESULTS_DIR/consolidated-sca-report.csv"
    echo "Repository,Issue_Type,Description,File_Path,Line_Number,CVE" > "$csv_file"
    for repo_url in "${REPOSITORIES[@]}"; do
        local repo_name
        repo_name=$(get_repo_name "$repo_url")
        local scan_file="$SCAN_RESULTS_DIR/$repo_name/srcclr-scan.txt"

        echo "\n##### Repository: $repo_name #####\n" >> "$SCAN_RESULTS_DIR/readable-scan-summary.txt"
        if [[ -f "$scan_file" ]]; then
            grep -A 5 -i "Vulnerability" "$scan_file" | while read -r line; do
                local issue_type=$(echo "$line" | grep -o 'Vulnerability.*' | cut -d':' -f2- | xargs)
                local description=$(echo "$line" | grep -o 'Description.*' | cut -d':' -f2- | xargs)
                local file_path=$(echo "$line" | grep -o 'File.*' | cut -d':' -f2- | xargs)
                local line_number=$(echo "$line" | grep -o 'Line.*' | cut -d':' -f2- | xargs)
                local cve=$(echo "$line" | grep -o 'CVE-.*' | xargs)
                echo "$repo_name,$issue_type,\"$description\",$file_path,$line_number,$cve" >> "$csv_file"
                echo "$line" >> "$SCAN_RESULTS_DIR/readable-scan-summary.txt"
            done
        else
            echo "$repo_name,No Issues Found,,,," >> "$csv_file"
            echo "No issues found for $repo_name" >> "$SCAN_RESULTS_DIR/readable-scan-summary.txt"
        fi
    done
    print_success "Consolidated CSV report generated at $csv_file and readable summary at readable-scan-summary.txt"
}

main() {
    mkdir -p "$BASE_DIR" "$SCAN_RESULTS_DIR"
    echo "SourceClear Bulk Scan Log - $(date)" > "$LOG_FILE"

    check_srcclr_setup

    for repo_url in "${REPOSITORIES[@]}"; do
        local repo_name
        repo_name=$(get_repo_name "$repo_url")
        print_status "Processing $repo_name"
        clone_and_prepare_repository "$repo_url"
        run_srcclr_scan "$repo_name"
    done

    generate_summary
}

main

