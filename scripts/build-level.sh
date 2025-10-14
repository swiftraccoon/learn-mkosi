#!/bin/bash
# Build a specific security level

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$REPO_ROOT/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 <level> [options]

Build a specific security level image for a specific OS distribution.

Arguments:
    level           Security level to build (0, 1, 2, or 3)

Options:
    -o, --os <os>   OS distribution (f42, rhel9, etc.) [default: f42]
    -f, --force     Force rebuild (clean output)
    -ff             Force rebuild and clean cache
    -fff            Force rebuild, clean cache and packages
    -h, --help      Show this help message

Examples:
    $0 0                Build Level 0 (Development) for Fedora 42
    $0 1                Build Level 1 (Baseline) for Fedora 42
    $0 1 --os rhel9     Build Level 1 for RHEL 9
    $0 2 -f             Rebuild Level 2 (Hardened) for Fedora 42
    $0 3 -o rhel9 -ff   Full rebuild Level 3 (Maximum) for RHEL 9

EOF
    exit 1
}

# Parse arguments
LEVEL=""
OS="f42"  # Default to Fedora 42
FORCE_FLAGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        0|1|2|3)
            LEVEL="$1"
            shift
            ;;
        -o|--os)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --os requires an argument${NC}"
                usage
            fi
            OS="$2"
            shift 2
            ;;
        -f)
            FORCE_FLAGS="-f"
            shift
            ;;
        -ff)
            FORCE_FLAGS="-ff"
            shift
            ;;
        -fff)
            FORCE_FLAGS="-fff"
            shift
            ;;
        --force)
            FORCE_FLAGS="-f"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown argument '$1'${NC}"
            usage
            ;;
    esac
done

if [ -z "$LEVEL" ]; then
    echo -e "${RED}Error: Security level required${NC}"
    usage
fi

# Map level to config directory
case $LEVEL in
    0)
        LEVEL_DIR="level-0-development"
        LEVEL_NAME="Level 0: Development"
        ;;
    1)
        LEVEL_DIR="level-1-minimal"
        LEVEL_NAME="Level 1: Baseline"
        ;;
    2)
        LEVEL_DIR="level-2-hardened"
        LEVEL_NAME="Level 2: Hardened"
        ;;
    3)
        LEVEL_DIR="level-3-maximum"
        LEVEL_NAME="Level 3: Maximum"
        ;;
    *)
        echo -e "${RED}Error: Invalid level '$LEVEL'. Must be 0, 1, 2, or 3${NC}"
        exit 1
        ;;
esac

# Build full config path with OS subdirectory
CONFIG_DIR="$REPO_ROOT/configs/$LEVEL_DIR/$OS"

if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}Error: Configuration directory not found: $CONFIG_DIR${NC}"
    echo -e "${YELLOW}Available OS configurations:${NC}"
    ls -1 "$REPO_ROOT/configs/$LEVEL_DIR/" 2>/dev/null | grep -v "mkosi.output" || echo "  (none found)"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building $LEVEL_NAME - $OS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration: ${CONFIG_DIR}${NC}"
echo -e "${YELLOW}OS: ${OS}${NC}"
echo -e "${YELLOW}Force flags: ${FORCE_FLAGS:-none}${NC}"
echo ""

# Find the best mkosi binary
# Prefer ~/.local/bin/mkosi (v26~devel) over system mkosi
MKOSI_BIN=""
if [ -n "${MKOSI:-}" ]; then
    # Allow user to specify MKOSI environment variable
    MKOSI_BIN="$MKOSI"
elif [ -x "$HOME/.local/bin/mkosi" ]; then
    MKOSI_BIN="$HOME/.local/bin/mkosi"
elif [ -x "/home/$SUDO_USER/.local/bin/mkosi" ] && [ -n "${SUDO_USER:-}" ]; then
    # When running as sudo, check the original user's .local/bin
    MKOSI_BIN="/home/$SUDO_USER/.local/bin/mkosi"
elif command -v mkosi &> /dev/null; then
    MKOSI_BIN="mkosi"
else
    echo -e "${RED}Error: mkosi not found${NC}"
    echo "Install mkosi: sudo dnf install mkosi"
    echo "Or from git: https://github.com/systemd/mkosi"
    exit 1
fi

# Check mkosi version
MKOSI_VERSION=$($MKOSI_BIN --version 2>&1 | head -n1 || echo "unknown")
echo -e "${BLUE}Using mkosi: ${MKOSI_BIN}${NC}"
echo -e "${BLUE}Version: ${MKOSI_VERSION}${NC}"
echo ""

# Warn if using old mkosi version
if [[ "$MKOSI_VERSION" =~ mkosi\ ([0-9]+) ]]; then
    MKOSI_MAJOR="${BASH_REMATCH[1]}"
    if [ "$MKOSI_MAJOR" -lt 26 ]; then
        echo -e "${YELLOW}Warning: mkosi v26+ recommended. Current version: $MKOSI_VERSION${NC}"
        echo -e "${YELLOW}Level configurations use features requiring mkosi v26+${NC}"
        echo ""
    fi
fi

# For Level 2+, check if keys exist
if [ "$LEVEL" -ge 2 ] && [ "$LEVEL" -ne 0 ]; then
    if [ ! -f "$CONFIG_DIR/mkosi.key" ] || [ ! -f "$CONFIG_DIR/mkosi.crt" ]; then
        echo -e "${YELLOW}Warning: Secure Boot keys not found${NC}"
        echo "Generate keys with: $MKOSI_BIN -C $CONFIG_DIR genkey"
        echo "Or continuing with mkosi auto-generation..."
        echo ""
    fi
fi

# Setup logging
mkdir -p "$LOGS_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOGS_DIR/level-${LEVEL}-${OS}-build-${TIMESTAMP}.log"

echo -e "${BLUE}Log file: ${LOG_FILE}${NC}"
echo ""

# Build the image with logging
echo -e "${GREEN}Starting build (output logged to ${LOG_FILE})...${NC}"
START_TIME=$(date +%s)

# Use script command to capture all terminal output including ANSI codes
# Fall back to tee if script is not available
if command -v script &> /dev/null; then
    # script command captures everything including progress bars
    if ! script -q -c "$MKOSI_BIN -C \"$CONFIG_DIR\" $FORCE_FLAGS build" "$LOG_FILE"; then
        echo ""
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}Build FAILED for $LEVEL_NAME${NC}"
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}See log: ${LOG_FILE}${NC}"
        exit 1
    fi
else
    # Fallback: redirect both stdout and stderr
    if ! $MKOSI_BIN -C "$CONFIG_DIR" $FORCE_FLAGS build 2>&1 | tee "$LOG_FILE"; then
        echo ""
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}Build FAILED for $LEVEL_NAME${NC}"
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}See log: ${LOG_FILE}${NC}"
        exit 1
    fi
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Extract errors and warnings from log
ERROR_COUNT=$(grep -i "error\|failed" "$LOG_FILE" | grep -v "Failed to disable unit.*does not exist" | wc -l 2>/dev/null || echo "0")
ERROR_COUNT=$(echo "$ERROR_COUNT" | tr -d '[:space:]')  # Remove any whitespace/newlines
WARNING_COUNT=$(grep -i "warning" "$LOG_FILE" | wc -l 2>/dev/null || echo "0")
WARNING_COUNT=$(echo "$WARNING_COUNT" | tr -d '[:space:]')  # Remove any whitespace/newlines

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build SUCCESSFUL for $LEVEL_NAME${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Build time: ${DURATION}s${NC}"
echo -e "${GREEN}Output directory: $CONFIG_DIR/mkosi.output/${NC}"
echo -e "${BLUE}Build log: ${LOG_FILE}${NC}"
echo ""

# Show warnings/errors summary
if [ "$ERROR_COUNT" -gt 0 ] || [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Build Summary:${NC}"
    [ "$ERROR_COUNT" -gt 0 ] && echo -e "  ${RED}Errors: ${ERROR_COUNT}${NC}"
    [ "$WARNING_COUNT" -gt 0 ] && echo -e "  ${YELLOW}Warnings: ${WARNING_COUNT}${NC}"
    echo -e "  Review log for details: ${BLUE}less $LOG_FILE${NC}"
    echo ""
fi

# Show output files
if [ -d "$CONFIG_DIR/mkosi.output" ]; then
    echo -e "${BLUE}Generated files:${NC}"
    ls -lh "$CONFIG_DIR/mkosi.output/" | grep -v "^total" | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
fi

# Rotate old logs (keep last 10 per level-os combination)
cd "$LOGS_DIR"
ls -t level-${LEVEL}-${OS}-build-*.log 2>/dev/null | tail -n +11 | xargs -r rm -f

# Provide next steps
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  Boot with QEMU:     ${BLUE}$MKOSI_BIN -C $CONFIG_DIR qemu${NC}"
echo -e "  Enter shell:        ${BLUE}$MKOSI_BIN -C $CONFIG_DIR shell${NC}"
echo -e "  Verify security:    ${BLUE}$SCRIPT_DIR/verify-security.sh $LEVEL --os $OS${NC}"
echo -e "  Review build log:   ${BLUE}less $LOG_FILE${NC}"
echo ""
