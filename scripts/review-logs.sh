#!/bin/bash
# Review build logs for errors and warnings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$REPO_ROOT/logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [log-file]

Review build logs for errors, warnings, and important messages.

Arguments:
    log-file    Optional: specific log file to review
                If not provided, shows latest log

Examples:
    $0                                         # Review latest log
    $0 logs/level-1-f42-build-20251012-*.log  # Review specific log
    $0 --list                                  # List all logs

EOF
    exit 1
}

list_logs() {
    echo -e "${BLUE}Available build logs:${NC}"
    echo ""
    ls -lht "$LOGS_DIR"/*.log 2>/dev/null | head -20 || echo "No logs found"
    exit 0
}

if [ "$#" -gt 0 ]; then
    case "$1" in
        -h|--help)
            usage
            ;;
        --list)
            list_logs
            ;;
        *)
            LOG_FILE="$1"
            ;;
    esac
else
    # Find latest log
    LOG_FILE=$(ls -t "$LOGS_DIR"/*.log 2>/dev/null | head -1 || echo "")
    if [ -z "$LOG_FILE" ]; then
        echo -e "${RED}No log files found in $LOGS_DIR${NC}"
        exit 1
    fi
fi

if [ ! -f "$LOG_FILE" ]; then
    echo -e "${RED}Log file not found: $LOG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Reviewing: $(basename "$LOG_FILE")${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Extract statistics
TOTAL_LINES=$(wc -l < "$LOG_FILE")
ERROR_LINES=$(grep -i "error\|failed" "$LOG_FILE" | grep -v "Failed to disable unit.*does not exist" | wc -l || echo "0")
WARNING_LINES=$(grep -i "warning" "$LOG_FILE" | wc -l || echo "0")
PACKAGE_COUNT=$(grep -o "Installing.*\[.*\]" "$LOG_FILE" | wc -l || echo "0")

echo -e "${YELLOW}Statistics:${NC}"
echo "  Total lines: $TOTAL_LINES"
echo "  Packages installed: $PACKAGE_COUNT"
echo "  Errors: $ERROR_LINES"
echo "  Warnings: $WARNING_LINES"
echo ""

# Show errors
if [ "$ERROR_LINES" -gt 0 ]; then
    echo -e "${RED}Errors found:${NC}"
    grep -i "error\|failed" "$LOG_FILE" | grep -v "Failed to disable unit.*does not exist" | head -20
    echo ""
fi

# Show warnings
if [ "$WARNING_LINES" -gt 0 ]; then
    echo -e "${YELLOW}Warnings found (showing first 20):${NC}"
    grep -i "warning" "$LOG_FILE" | head -20
    echo ""
fi

# Extract build time
if grep -q "Build time:" "$LOG_FILE"; then
    echo -e "${GREEN}Build completed successfully${NC}"
    grep "Build time:" "$LOG_FILE" | tail -1
    echo ""
fi

# Show recent activity (last 30 lines)
echo -e "${BLUE}Recent activity (last 30 lines):${NC}"
tail -30 "$LOG_FILE"
echo ""

echo -e "${YELLOW}Commands:${NC}"
echo -e "  View full log:      ${BLUE}less $LOG_FILE${NC}"
echo -e "  Search for text:    ${BLUE}grep 'search' $LOG_FILE${NC}"
echo -e "  View all errors:    ${BLUE}grep -i error $LOG_FILE | less${NC}"
echo -e "  View all warnings:  ${BLUE}grep -i warning $LOG_FILE | less${NC}"
echo ""
