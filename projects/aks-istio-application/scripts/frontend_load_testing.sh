#!/bin/bash

# Set 'set -e' to exit immediately if any command fails
set -e

# Function to display script usage
usage() {
    echo "Usage: $0 <page_url> [sleep_time]"
    echo "Example: $0 http://example.com 1"
    exit 1
}

# Check for required arguments
if [ $# -lt 1 ]; then
    usage
fi

# Assign command-line arguments to variables
PAGE_URL="$1"
SLEEP_TIME="${2:-1}"  # Default sleep time is 1 second

# Main function to perform load testing
perform_load_testing() {
    echo "Testing frontend page workload..."
    echo "Sending curl command to $PAGE_URL..."
    for ((i = 1; i <= 1000; i++)); do
        echo "Try number $i..."
        if ! curl -s -o /dev/null "$PAGE_URL"; then
            echo "Failed to fetch page: $PAGE_URL"
            exit 1
        fi
        sleep "$SLEEP_TIME"
    done
    echo "Testing frontend page completed!"
}

# Prompt for sleep time if not provided
if [ -z "$2" ]; then
    read -rp "Enter sleep time (default is 1 second): " SLEEP_TIME
fi

# Call the main function
perform_load_testing
