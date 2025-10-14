#!/bin/bash
# Verify security configuration of a built image

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <level> [options]

Verify security configuration of a built image.

Arguments:
    level           Security level to verify (0, 1, 2, or 3)

Options:
    -o, --os <os>   OS distribution (f42, rhel9, etc.) [default: f42]
    -h, --help      Show this help message

Examples:
    $0 0                Verify Level 0 (Development) for Fedora 42
    $0 1                Verify Level 1 (Baseline) for Fedora 42
    $0 1 --os rhel9     Verify Level 1 for RHEL 9
    $0 2 -o f42         Verify Level 2 for Fedora 42

Note: Level 0 has minimal security checks (development only)

EOF
    exit 1
}

# Parse arguments
LEVEL=""
OS="f42"  # Default to Fedora 42

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

# Map level to directory name
case $LEVEL in
    0)
        LEVEL_DIR="level-0-development"
        ;;
    1)
        LEVEL_DIR="level-1-minimal"
        ;;
    2)
        LEVEL_DIR="level-2-hardened"
        ;;
    3)
        LEVEL_DIR="level-3-maximum"
        ;;
esac

CONFIG_NAME="$LEVEL_DIR"
CONFIG_DIR="$REPO_ROOT/configs/$LEVEL_DIR/$OS"

if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}Error: Configuration directory not found: $CONFIG_DIR${NC}"
    exit 1
fi

if [ ! -d "$CONFIG_DIR/mkosi.output" ]; then
    echo -e "${RED}Error: Image not built. Run build-level.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Security Verification: $CONFIG_NAME - $OS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

check_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((CHECKS_WARNING++))
}

echo -e "${YELLOW}Running security checks via mkosi shell...${NC}"
echo ""

# Check SELinux
echo -e "${BLUE}Checking SELinux configuration...${NC}"
if mkosi -C "$CONFIG_DIR" shell -- getenforce 2>/dev/null | grep -q "Enforcing"; then
    check_pass "SELinux is in enforcing mode"
else
    check_fail "SELinux is not in enforcing mode"
fi

# Check firewall
echo -e "${BLUE}Checking firewall...${NC}"
if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled firewalld 2>/dev/null | grep -q "enabled"; then
    check_pass "Firewalld is enabled"
else
    check_warn "Firewalld is not enabled"
fi

# Check for minimal package count (Level 0-1)
if [[ "$CONFIG_NAME" == *"level-0"* ]] || [[ "$CONFIG_NAME" == *"level-1"* ]]; then
    echo -e "${BLUE}Checking package count...${NC}"
    PKG_COUNT=$(mkosi -C "$CONFIG_DIR" shell -- rpm -qa | wc -l)
    if [[ "$CONFIG_NAME" == *"level-0"* ]] && [ "$PKG_COUNT" -lt 200 ]; then
        check_pass "Package count is minimal for development ($PKG_COUNT packages)"
    elif [[ "$CONFIG_NAME" == *"level-1"* ]] && [ "$PKG_COUNT" -lt 260 ]; then
        check_pass "Package count is reasonable for production baseline ($PKG_COUNT packages)"
    elif [[ "$CONFIG_NAME" == *"level-1"* ]] && [ "$PKG_COUNT" -ge 260 ]; then
        check_warn "Package count is higher than expected ($PKG_COUNT packages, expected <260)"
    elif [[ "$CONFIG_NAME" == *"level-0"* ]] && [ "$PKG_COUNT" -ge 200 ]; then
        check_warn "Package count is higher than expected ($PKG_COUNT packages, expected <200)"
    fi
fi

# Check Level 1 production features
if [[ "$CONFIG_NAME" == *"level-1"* ]]; then
    echo -e "${BLUE}Checking production baseline features (Level 1)...${NC}"

    # Check SSH server
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled sshd 2>/dev/null | grep -q "enabled"; then
        check_pass "SSH server is enabled"
    else
        check_fail "SSH server is not enabled (required for Level 1)"
    fi

    # Check audit
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled auditd 2>/dev/null | grep -q "enabled"; then
        check_pass "Audit daemon is enabled"
    else
        check_fail "Audit daemon is not enabled (required for Level 1)"
    fi

    # Check automated updates
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled dnf-automatic.timer 2>/dev/null | grep -q "enabled"; then
        check_pass "Automated security updates are enabled"
    else
        check_fail "Automated security updates are not enabled"
    fi

    # Check AIDE timer
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled aide-check.timer 2>/dev/null | grep -q "enabled"; then
        check_pass "AIDE file integrity monitoring is enabled"
    else
        check_warn "AIDE file integrity monitoring is not enabled"
    fi
fi

# Check for audit (Level 2+)
if [[ "$CONFIG_NAME" == *"level-2"* ]] || [[ "$CONFIG_NAME" == *"level-3"* ]]; then
    echo -e "${BLUE}Checking audit system (Level 2+)...${NC}"
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled auditd 2>/dev/null | grep -q "enabled"; then
        check_pass "Audit daemon is enabled"
    else
        check_fail "Audit daemon is not enabled"
    fi
fi

# Check for fail2ban (Level 2+)
if [[ "$CONFIG_NAME" == *"level-2"* ]] || [[ "$CONFIG_NAME" == *"level-3"* ]]; then
    echo -e "${BLUE}Checking fail2ban (Level 2+)...${NC}"
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled fail2ban 2>/dev/null | grep -q "enabled"; then
        check_pass "Fail2ban is enabled"
    else
        check_fail "Fail2ban is not enabled"
    fi
fi

# Check for FIPS (Level 3)
if [[ "$CONFIG_NAME" == *"level-3"* ]]; then
    echo -e "${BLUE}Checking FIPS mode (Level 3)...${NC}"
    if mkosi -C "$CONFIG_DIR" shell -- cat /proc/sys/crypto/fips_enabled 2>/dev/null | grep -q "1"; then
        check_pass "FIPS mode is enabled"
    else
        check_warn "FIPS mode not enabled (requires first boot with fips=1 kernel param)"
    fi
fi

# Check for USBGuard (Level 3)
if [[ "$CONFIG_NAME" == *"level-3"* ]]; then
    echo -e "${BLUE}Checking USBGuard (Level 3)...${NC}"
    if mkosi -C "$CONFIG_DIR" shell -- systemctl is-enabled usbguard 2>/dev/null | grep -q "enabled"; then
        check_pass "USBGuard is enabled"
    else
        check_warn "USBGuard is not enabled"
    fi
fi

# Check systemd security
echo -e "${BLUE}Checking systemd service security...${NC}"
if mkosi -C "$CONFIG_DIR" shell -- systemd-analyze security --no-pager 2>/dev/null | head -5 | grep -q "MEDIUM\\|OK"; then
    check_pass "Systemd services have security hardening"
else
    check_warn "Some systemd services may lack security hardening"
fi

# Check for sysctl hardening
echo -e "${BLUE}Checking kernel hardening (sysctl)...${NC}"
if mkosi -C "$CONFIG_DIR" shell -- test -f /etc/sysctl.d/99-security.conf 2>/dev/null; then
    check_pass "Kernel hardening sysctl configuration present"
else
    check_fail "Kernel hardening sysctl configuration missing"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Security Verification Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Checks passed:  ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Checks failed:  ${RED}$CHECKS_FAILED${NC}"
echo -e "Warnings:       ${YELLOW}$CHECKS_WARNING${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All critical security checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some security checks failed. Review configuration.${NC}"
    exit 1
fi
