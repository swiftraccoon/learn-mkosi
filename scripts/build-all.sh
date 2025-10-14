#!/bin/bash
# Build all security levels sequentially

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
OS="f42"  # Default to Fedora 42

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--os)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --os requires an argument${NC}"
                exit 1
            fi
            OS="$2"
            shift 2
            ;;
        -h|--help)
            cat <<EOF
Usage: $0 [options]

Build all security levels (0-3) for a specific OS distribution.

Options:
    -o, --os <os>   OS distribution (f42, rhel9, etc.) [default: f42]
    -h, --help      Show this help message

Examples:
    $0              Build all levels (0-3) for Fedora 42
    $0 --os rhel9   Build all levels for RHEL 9

Note: Level 0 is for development only. Production builds start at Level 1.

EOF
            exit 0
            ;;
        -f|-ff|-fff)
            # These will be passed through to build-level.sh
            EXTRA_FLAGS="$1"
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown argument '$1'${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building All Security Levels (0-3) - $OS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

TOTAL_START=$(date +%s)
FAILED_LEVELS=()

for LEVEL in 0 1 2 3; do
    echo -e "${BLUE}Building Level $LEVEL - $OS...${NC}"
    echo ""

    if "$SCRIPT_DIR/build-level.sh" "$LEVEL" --os "$OS" ${EXTRA_FLAGS:-}; then
        echo -e "${GREEN}Level $LEVEL - $OS: SUCCESS${NC}"
    else
        echo -e "${RED}Level $LEVEL - $OS: FAILED${NC}"
        FAILED_LEVELS+=("$LEVEL")
    fi

    echo ""
    echo "----------------------------------------"
    echo ""
done

TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Total time: ${TOTAL_DURATION}s"
echo ""

if [ ${#FAILED_LEVELS[@]} -eq 0 ]; then
    echo -e "${GREEN}All levels built successfully!${NC}"
    exit 0
else
    echo -e "${RED}Failed levels: ${FAILED_LEVELS[*]}${NC}"
    exit 1
fi
