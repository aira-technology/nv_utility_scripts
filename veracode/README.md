# Veracode Utility Scripts

This directory contains utility scripts for automating Veracode security scans and checking scan statuses.

## Prerequisites

- Veracode account with API access
- Valid Veracode API credentials
- Python 3.6+ (for the status checker script)
- Bash shell (for the scan scripts)

## Setup

### 1. Environment Variables

Before using these scripts, you must set up your Veracode API credentials as environment variables.

#### Setting Environment Variables

**For current session (temporary):**
```bash
export VERACODE_API_ID="your_api_id_here"
export VERACODE_API_KEY="your_api_key_here"
```

**For permanent setup (recommended):**

Add the following lines to your shell profile file (`~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`):
```bash
export VERACODE_API_ID="your_api_id_here"
export VERACODE_API_KEY="your_api_key_here"
```

Then reload your profile:
```bash
source ~/.zshrc  # or ~/.bashrc or ~/.bash_profile
```

#### Getting Your Veracode API Credentials

1. Log into the Veracode Platform
2. Go to **Administration** → **API Credentials**
3. Generate new API credentials if you don't have them
4. Copy the API ID and API Key

### 2. Verify Setup

Check that your environment variables are set correctly:
```bash
echo "API ID: $VERACODE_API_ID"
echo "API Key: $VERACODE_API_KEY"
```

## Scripts Overview

### 1. `run_single_scan.sh`
Runs a single Veracode scan for a specified application.

### 2. `veracode_bulk_scan.sh`
Runs multiple Veracode scans from a configuration file.

### 3. `check_all_repos_status.py`
Checks the status of all Veracode scans across repositories.

## Usage Instructions

### Running a Single Scan

```bash
./run_single_scan.sh -a "MyApplication" -v "1.0.0" -f "/path/to/application/files"
```

**Parameters:**
- `-a`: Application name in Veracode
- `-v`: Version/build name
- `-f`: Path to the file or directory to scan
- `-h`: Display help message

**Example:**
```bash
./run_single_scan.sh -a "WebApp" -v "2.1.0" -f "./build/webapp.jar"
```

### Running Bulk Scans

First, create a CSV configuration file with your applications:

**config.csv:**
```csv
app_name,version,filepath
WebApp,1.0.0,/path/to/webapp.jar
MobileApp,2.0.0,/path/to/mobile-app
APIService,1.5.0,/path/to/api-service.war
```

Then run the bulk scan:
```bash
./veracode_bulk_scan.sh -c config.csv -l ./scan_logs
```

**Parameters:**
- `-c`: Configuration file path (required)
- `-l`: Log directory (optional, default: ./logs)
- `-h`: Display help message

### Checking Scan Status

Check the status of all your Veracode scans:

**Table format (default):**
```bash
./check_all_repos_status.py
```

**JSON format:**
```bash
./check_all_repos_status.py --format json
```

**CSV format:**
```bash
./check_all_repos_status.py --format csv
```

**Parameters:**
- `--format` or `-f`: Output format (table, json, csv)
- `--config` or `-c`: Path to configuration file (optional)
- `--help`: Display help message

## File Permissions

Make sure the scripts have execute permissions:
```bash
chmod +x run_single_scan.sh
chmod +x veracode_bulk_scan.sh
chmod +x check_all_repos_status.py
```

## Troubleshooting

### Common Issues

1. **Permission Denied Error**
   ```bash
   chmod +x script_name.sh
   ```

2. **Environment Variables Not Set**
   ```
   Error: VERACODE_API_ID and VERACODE_API_KEY environment variables must be set
   ```
   - Verify your environment variables are set correctly
   - Check for typos in variable names

3. **File Not Found Error**
   - Ensure the file paths in your configuration are correct
   - Use absolute paths when possible

4. **API Authentication Issues**
   - Verify your API credentials are valid
   - Check that your Veracode account has the necessary permissions

### Logs

- Single scan logs: Output to console
- Bulk scan logs: Individual log files created in the specified log directory
- Status checker: Output to console in specified format

## Configuration File Format

For bulk scans, use a CSV file with the following format:

```csv
app_name,version,filepath
Application1,1.0.0,/path/to/app1
Application2,2.0.0,/path/to/app2
Application3,1.5.0,/path/to/app3
```

**Important Notes:**
- First line is the header (required)
- No spaces around commas unless they're part of the actual values
- Use absolute paths for reliability
- Ensure all specified files/directories exist

## Security Best Practices

1. **Never commit API credentials to version control**
2. **Use environment variables for sensitive information**
3. **Regularly rotate your API keys**
4. **Limit API key permissions to minimum required**
5. **Store credentials securely on production systems**

## Support

For issues with these scripts:
1. Check the troubleshooting section above
2. Verify your Veracode account and API credentials
3. Review the script logs for detailed error messages

For Veracode platform issues, consult the official Veracode documentation or contact Veracode support.

## Script Customization

These scripts provide a foundation that you can customize for your specific needs:

- Modify the Veracode API calls to match your organization's requirements
- Add additional validation or error handling
- Integrate with your CI/CD pipeline
- Add notification mechanisms (email, Slack, etc.)

## Dependencies

### Python Dependencies (for check_all_repos_status.py)
```bash
pip install requests
```

### System Requirements
- Bash 4.0+ (for shell scripts)
- Python 3.6+ (for status checker)
- curl (may be needed for API calls)
- Valid Veracode account and API access
