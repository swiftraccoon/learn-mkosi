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
    -o, --os <os>           OS distribution (f42, rhel9, etc.) [default: f42]
    -p, --profile <type>   Partition scheme profile (standard, btrfs-partitions, btrfs-subvolumes)
                           [default: btrfs-partitions for Fedora, standard for RHEL/CentOS]
    -f, --force            Force rebuild (clean output)
    -ff                    Force rebuild and clean cache
    -fff                   Force rebuild, clean cache and packages
    -h, --help             Show this help message

Partition Scheme Profiles (Level 0 only):
    standard          - Traditional ext4 partitioning (CIS-compliant)
    btrfs-partitions  - Btrfs with separate partitions (default, CIS-compliant)
    btrfs-subvolumes  - Single btrfs partition with subvolumes

Examples:
    $0 0                        Build Level 0 (Development) for Fedora 42
    $0 0 -p standard            Build Level 0 with ext4 partitions
    $0 0 -p btrfs-subvolumes    Build Level 0 with btrfs subvolumes
    $0 1                        Build Level 1 (Baseline) for Fedora 42
    $0 1 --os rhel9             Build Level 1 for RHEL 9
    $0 2 -f                     Force rebuild Level 2 (Hardened) for Fedora 42
    $0 3 -o rhel9 -ff           Full rebuild Level 3 (Maximum) for RHEL 9

EOF
    exit 1
}

# Parse arguments
LEVEL=""
OS="f42"  # Default to Fedora 42
PARTITION_SCHEME=""  # Will be set based on OS
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
        -p|--profile|--partition)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo -e "${RED}Error: --profile requires an argument${NC}"
                usage
            fi
            PARTITION_SCHEME="$2"
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

# Build full config path
# Level 0 uses consolidated config with drop-ins, other levels use OS subdirectories
if [ "$LEVEL" -eq 0 ]; then
    CONFIG_DIR="$REPO_ROOT/configs/$LEVEL_DIR"

    # Parse OS parameter to extract distribution and release for mkosi
    case $OS in
        f42|fedora42)
            MKOSI_DISTRIBUTION="fedora"
            MKOSI_RELEASE="42"
            ;;
        f43|fedora43)
            MKOSI_DISTRIBUTION="fedora"
            MKOSI_RELEASE="43"
            ;;
        rawhide|fedorarawhide)
            MKOSI_DISTRIBUTION="fedora"
            MKOSI_RELEASE="rawhide"
            ;;
        rhel9)
            MKOSI_DISTRIBUTION="rhel"
            MKOSI_RELEASE="9"
            ;;
        rhel10)
            MKOSI_DISTRIBUTION="rhel"
            MKOSI_RELEASE="10"
            ;;
        centos9)
            MKOSI_DISTRIBUTION="centos"
            MKOSI_RELEASE="9"
            ;;
        centos10)
            MKOSI_DISTRIBUTION="centos"
            MKOSI_RELEASE="10"
            ;;
        *)
            echo -e "${RED}Error: Unknown OS '$OS' for Level 0${NC}"
            echo -e "${YELLOW}Supported: f42, f43, rawhide, rhel9, rhel10, centos9, centos10${NC}"
            exit 1
            ;;
    esac

    # Set default partition scheme based on distribution
    # RHEL/CentOS don't support btrfs, so default to standard (ext4)
    if [ -z "$PARTITION_SCHEME" ]; then
        case $MKOSI_DISTRIBUTION in
            rhel|centos)
                PARTITION_SCHEME="standard"
                ;;
            fedora)
                PARTITION_SCHEME="btrfs-partitions"
                ;;
            *)
                PARTITION_SCHEME="standard"
                ;;
        esac
    fi

    # Validate partition scheme
    case $PARTITION_SCHEME in
        standard|btrfs-partitions|btrfs-subvolumes)
            # Valid scheme
            ;;
        *)
            echo -e "${RED}Error: Invalid partition scheme '$PARTITION_SCHEME'${NC}"
            echo -e "${YELLOW}Valid schemes: standard, btrfs-partitions, btrfs-subvolumes${NC}"
            exit 1
            ;;
    esac
else
    CONFIG_DIR="$REPO_ROOT/configs/$LEVEL_DIR/$OS"
fi

if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}Error: Configuration directory not found: $CONFIG_DIR${NC}"
    if [ "$LEVEL" -ne 0 ]; then
        echo -e "${YELLOW}Available OS configurations:${NC}"
        ls -1 "$REPO_ROOT/configs/$LEVEL_DIR/" 2>/dev/null | grep -v "mkosi.output" | grep -v "mkosi.conf" || echo "  (none found)"
    fi
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building $LEVEL_NAME - $OS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration: ${CONFIG_DIR}${NC}"
echo -e "${YELLOW}OS: ${OS}${NC}"
echo -e "${YELLOW}Force flags: ${FORCE_FLAGS:-none}${NC}"
if [ "$LEVEL" -eq 0 ]; then
    echo -e "${YELLOW}Profile: ${PARTITION_SCHEME}${NC}"

    # Validate that profile directory exists
    PROFILE_DIR="$CONFIG_DIR/mkosi.profiles/${PARTITION_SCHEME}"
    if [ ! -d "$PROFILE_DIR" ]; then
        echo -e "${RED}Error: Profile not found: $PROFILE_DIR${NC}"
        echo -e "${YELLOW}Available profiles:${NC}"
        ls -1 "$CONFIG_DIR/mkosi.profiles/" 2>/dev/null | sed 's/^/  /'
        exit 1
    fi
fi
echo ""

# Cleanup on interruption
trap 'echo -e "\n${YELLOW}Build interrupted${NC}"; exit 130' INT TERM

# Find the best mkosi binary
# Prefer ~/.local/bin/mkosi (v26) over system mkosi
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

# Build mkosi command as array for safe argument handling
MKOSI_ARGS=(-C "$CONFIG_DIR")

if [ "$LEVEL" -eq 0 ]; then
    MKOSI_ARGS+=(-d "$MKOSI_DISTRIBUTION" -r "$MKOSI_RELEASE")
    MKOSI_ARGS+=(--profile="$PARTITION_SCHEME")
fi

if [ -n "$FORCE_FLAGS" ]; then
    MKOSI_ARGS+=("$FORCE_FLAGS")
fi

MKOSI_ARGS+=(build)

echo -e "${BLUE}Command: $MKOSI_BIN ${MKOSI_ARGS[*]}${NC}"
echo ""

# Run mkosi with output logged via tee (pipefail catches mkosi failures)
if ! "$MKOSI_BIN" "${MKOSI_ARGS[@]}" 2>&1 | tee "$LOG_FILE"; then
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Build FAILED for $LEVEL_NAME${NC}"
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}See log: ${LOG_FILE}${NC}"
    exit 1
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
if [ "$LEVEL" -eq 0 ]; then
    echo -e "${GREEN}Output directory: $CONFIG_DIR/mkosi.output/$OS/${NC}"
else
    echo -e "${GREEN}Output directory: $CONFIG_DIR/mkosi.output/${NC}"
fi
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
if [ "$LEVEL" -eq 0 ]; then
    OUTPUT_FILES_DIR="$CONFIG_DIR/mkosi.output/$OS"
else
    OUTPUT_FILES_DIR="$CONFIG_DIR/mkosi.output"
fi

if [ -d "$OUTPUT_FILES_DIR" ]; then
    echo -e "${BLUE}Generated files:${NC}"
    ls -lh "$OUTPUT_FILES_DIR/" | grep -v "^total" | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
fi

# Rotate old logs (keep last 10 per level-os combination)
cd "$LOGS_DIR"
OLD_LOGS=$(ls -t level-${LEVEL}-${OS}-build-*.log 2>/dev/null | tail -n +11)
if [ -n "$OLD_LOGS" ]; then
    echo -e "${YELLOW}Rotating old logs (keeping last 10)${NC}"
    echo "$OLD_LOGS" | xargs rm -f
fi

# Provide next steps
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  Boot with QEMU:     ${BLUE}$MKOSI_BIN -C $CONFIG_DIR qemu${NC}"
echo -e "  Enter shell:        ${BLUE}$MKOSI_BIN -C $CONFIG_DIR shell${NC}"
echo -e "  Verify security:    ${BLUE}$SCRIPT_DIR/verify-security.sh $LEVEL --os $OS${NC}"
echo -e "  Review build log:   ${BLUE}less $LOG_FILE${NC}"
echo ""
