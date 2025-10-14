#!/bin/bash
# Run QEMU directly on built mkosi images
# Bypasses mkosi's qemu wrapper for faster iteration and more control

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 <level> [options]

Run a built security level image directly with QEMU.

Arguments:
    level           Security level to run (0, 1, 2, or 3)

Options:
    -o, --os <os>   OS distribution (f42, rhel9, etc.) [default: f42]
    -m, --memory    RAM in MB [default: 2048]
    -c, --cpus      Number of CPUs [default: 2]
    -k, --kvm       Force KVM acceleration [default: auto-detect]
    -s, --snapshot  Use snapshot mode (default, non-destructive)
    -w, --rw        Write to disk image directly
    -p, --port      SSH port forwarding [default: 10022]
    -g, --gdb       Enable GDB stub on port 1234
    -d, --debug     Enable verbose debugging
    -h, --help      Show this help message

Examples:
    $0 0                    Run Level 0 (Development) for Fedora 42
    $0 1                    Run Level 1 (Baseline) for Fedora 42
    $0 2 --os rhel9         Run Level 2 for RHEL 9
    $0 3 --memory 4096      Run Level 3 with 4GB RAM
    $0 1 --rw               Run Level 1 with writable disk

Notes:
    - Images must be built first with scripts/build-level.sh
    - Snapshot mode (default) preserves the original image
    - KVM acceleration is auto-detected if /dev/kvm is accessible
    - SSH is accessible via: ssh -p <port> root@localhost

EOF
    exit 1
}

die() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}$*${NC}"
}

success() {
    echo -e "${GREEN}$*${NC}"
}

warn() {
    echo -e "${YELLOW}$*${NC}"
}

# Parse arguments
LEVEL=""
OS="f42"
MEMORY=2048
CPUS=2
KVM_AUTO=1
KVM_FORCE=0
SNAPSHOT=1
SSH_PORT=10022
GDB=""
DEBUG=0

while [[ $# -gt 0 ]]; do
    case $1 in
        0|1|2|3)
            LEVEL="$1"
            shift
            ;;
        -o|--os)
            if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
                die "--os requires an argument"
            fi
            OS="$2"
            shift 2
            ;;
        -m|--memory)
            if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
                die "--memory requires an argument"
            fi
            MEMORY="$2"
            shift 2
            ;;
        -c|--cpus)
            if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
                die "--cpus requires an argument"
            fi
            CPUS="$2"
            shift 2
            ;;
        -k|--kvm)
            KVM_FORCE=1
            shift
            ;;
        -s|--snapshot)
            SNAPSHOT=1
            shift
            ;;
        -w|--rw)
            SNAPSHOT=0
            shift
            ;;
        -p|--port)
            if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
                die "--port requires an argument"
            fi
            SSH_PORT="$2"
            shift 2
            ;;
        -g|--gdb)
            GDB="-s -S"
            shift
            ;;
        -d|--debug)
            DEBUG=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            die "Unknown argument '$1'"
            ;;
    esac
done

if [ -z "$LEVEL" ]; then
    die "Security level required"
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
        die "Invalid level '$LEVEL'. Must be 0, 1, 2, or 3"
        ;;
esac

CONFIG_DIR="$REPO_ROOT/configs/$LEVEL_DIR/$OS"

if [ ! -d "$CONFIG_DIR" ]; then
    die "Configuration directory not found: $CONFIG_DIR"
fi

OUTPUT_DIR="$CONFIG_DIR/mkosi.output"

if [ ! -d "$OUTPUT_DIR" ]; then
    die "Output directory not found: $OUTPUT_DIR
Build the image first with: scripts/build-level.sh $LEVEL --os $OS"
fi

# Find the disk image (handle compressed images)
IMAGE=""
COMPRESSED=""

# First try to find uncompressed images
for ext in raw qcow2 img; do
    candidates=($(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.$ext" ! -name "*.zst" 2>/dev/null | sort))
    if [ ${#candidates[@]} -gt 0 ]; then
        IMAGE="${candidates[0]}"
        break
    fi
done

# If no uncompressed image, look for compressed
if [ -z "$IMAGE" ]; then
    for ext in raw.zst qcow2.zst img.zst; do
        candidates=($(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.$ext" 2>/dev/null | sort))
        if [ ${#candidates[@]} -gt 0 ]; then
            COMPRESSED="${candidates[0]}"
            break
        fi
    done

    if [ -n "$COMPRESSED" ]; then
        info "Found compressed image: $(basename "$COMPRESSED")"
        info "Decompressing..."
        IMAGE="${COMPRESSED%.zst}"

        # Decompress if not already done
        if [ ! -f "$IMAGE" ] || [ "$COMPRESSED" -nt "$IMAGE" ]; then
            if ! command -v zstd &> /dev/null; then
                die "Image is compressed but zstd is not installed. Install with: sudo dnf install zstd"
            fi
            zstd -d -f "$COMPRESSED" -o "$IMAGE"
        else
            info "Using existing decompressed image"
        fi
    fi
fi

if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    die "No disk image found in $OUTPUT_DIR
Build the image first with: scripts/build-level.sh $LEVEL --os $OS"
fi

info "========================================"
info "Running $LEVEL_NAME - $OS"
info "========================================"
echo ""
info "Image: $IMAGE"
info "Memory: ${MEMORY}MB"
info "CPUs: $CPUS"

# Detect KVM support
KVM_AVAILABLE=0
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_AVAILABLE=1
fi

USE_KVM=0
if [ $KVM_FORCE -eq 1 ]; then
    if [ $KVM_AVAILABLE -eq 0 ]; then
        die "KVM acceleration forced but /dev/kvm is not accessible"
    fi
    USE_KVM=1
elif [ $KVM_AUTO -eq 1 ] && [ $KVM_AVAILABLE -eq 1 ]; then
    USE_KVM=1
fi

if [ $USE_KVM -eq 1 ]; then
    info "Acceleration: KVM"
else
    warn "Acceleration: TCG (software emulation, will be slower)"
fi

# Detect QEMU binary
QEMU=""
for binary in qemu-system-x86_64 qemu-kvm; do
    if command -v "$binary" &> /dev/null; then
        QEMU="$binary"
        break
    fi
done

if [ -z "$QEMU" ]; then
    die "QEMU not found. Install with: sudo dnf install qemu-system-x86"
fi

QEMU_VERSION=$($QEMU --version | head -n1)
info "QEMU: $QEMU_VERSION"

# Detect OVMF firmware for UEFI
OVMF_CODE=""
OVMF_VARS_TEMPLATE=""

# Try Fedora locations
for code_path in \
    /usr/share/edk2/ovmf/OVMF_CODE.fd \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/qemu/ovmf-x86_64-code.bin
do
    if [ -f "$code_path" ]; then
        OVMF_CODE="$code_path"
        break
    fi
done

# Find matching vars template
if [ -n "$OVMF_CODE" ]; then
    OVMF_DIR=$(dirname "$OVMF_CODE")
    OVMF_BASENAME=$(basename "$OVMF_CODE")
    VARS_BASENAME="${OVMF_BASENAME/CODE/VARS}"

    if [ -f "$OVMF_DIR/$VARS_BASENAME" ]; then
        OVMF_VARS_TEMPLATE="$OVMF_DIR/$VARS_BASENAME"
    fi
fi

if [ -z "$OVMF_CODE" ]; then
    warn "OVMF firmware not found, using BIOS boot"
    info "For UEFI boot, install: sudo dnf install edk2-ovmf"
    FIRMWARE_TYPE="bios"
else
    info "Firmware: UEFI ($OVMF_CODE)"
    FIRMWARE_TYPE="uefi"
fi

# Create temporary OVMF vars if using UEFI
OVMF_VARS=""
if [ "$FIRMWARE_TYPE" = "uefi" ] && [ -n "$OVMF_VARS_TEMPLATE" ]; then
    OVMF_VARS=$(mktemp --tmpdir "mkosi-ovmf-vars-XXXXXX.fd")
    cp "$OVMF_VARS_TEMPLATE" "$OVMF_VARS"
    trap "rm -f '$OVMF_VARS'" EXIT
fi

# Setup snapshot overlay if requested
DISK_IMAGE="$IMAGE"
if [ $SNAPSHOT -eq 1 ]; then
    info "Mode: Snapshot (read-only, changes discarded)"
    OVERLAY=$(mktemp --tmpdir "mkosi-overlay-XXXXXX.qcow2")
    qemu-img create -f qcow2 -F raw -b "$IMAGE" "$OVERLAY" > /dev/null 2>&1
    DISK_IMAGE="$OVERLAY"
    trap "rm -f '$OVMF_VARS' '$OVERLAY'" EXIT
else
    warn "Mode: Read-Write (changes will be written to disk!)"
fi

echo ""
success "Starting QEMU..."
echo ""

# Build QEMU command
QEMU_CMD=(
    "$QEMU"
    -machine "q35"
    -smp "$CPUS"
    -m "${MEMORY}M"
)

# Add KVM acceleration
if [ $USE_KVM -eq 1 ]; then
    QEMU_CMD+=(-accel kvm -cpu host)
else
    QEMU_CMD+=(-accel tcg -cpu qemu64)
fi

# Add firmware
if [ "$FIRMWARE_TYPE" = "uefi" ]; then
    QEMU_CMD+=(
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    )
    if [ -n "$OVMF_VARS" ]; then
        QEMU_CMD+=(-drive "if=pflash,format=raw,file=$OVMF_VARS")
    fi
fi

# Detect image format for proper boot
if [ $SNAPSHOT -eq 1 ]; then
    BLOCKDEV_DRIVER="qcow2"
    BLOCKDEV_FILE="file.driver=file,file.filename=$DISK_IMAGE"
else
    BLOCKDEV_DRIVER="raw"
    BLOCKDEV_FILE="file.driver=file,file.filename=$DISK_IMAGE,file.aio=io_uring"
fi

# Add disk as bootable device using modern blockdev approach
# This matches mkosi's implementation for proper UEFI boot
QEMU_CMD+=(
    -blockdev "$BLOCKDEV_DRIVER,node-name=mkosi,discard=unmap,$BLOCKDEV_FILE"
    -device "virtio-blk-pci,drive=mkosi,bootindex=1"
)

# Add devices
QEMU_CMD+=(
    # Random number generator
    -device "virtio-rng-pci"

    # No graphical display
    -nographic
    -nodefaults

    # Virtio console for serial output (matches mkosi)
    -chardev "stdio,mux=on,id=console,signal=off"
    -device "virtio-serial-pci,id=mkosi-virtio-serial-pci"
    -device "virtconsole,chardev=console"
    -mon "console"

    # User-mode networking with SSH forwarding
    -nic "user,model=virtio-net-pci,hostfwd=tcp::${SSH_PORT}-:22"
)

# Add GDB if requested
if [ -n "$GDB" ]; then
    info "GDB: Enabled on port 1234"
    QEMU_CMD+=($GDB)
fi

# Debug output
if [ $DEBUG -eq 1 ]; then
    info "Full QEMU command:"
    echo "${QEMU_CMD[@]}"
    echo ""
fi

echo ""
# Check if SSH port is available
if ss -tln 2>/dev/null | grep -q ":${SSH_PORT} "; then
    warn "Port $SSH_PORT is already in use!"

    # Find next available port
    ORIGINAL_PORT=$SSH_PORT
    for port in $(seq $((SSH_PORT + 1)) $((SSH_PORT + 100))); do
        if ! ss -tln 2>/dev/null | grep -q ":${port} "; then
            SSH_PORT=$port
            info "Using alternative port: $SSH_PORT"

            # Update QEMU command with new port
            for i in "${!QEMU_CMD[@]}"; do
                if [[ "${QEMU_CMD[$i]}" == *"hostfwd=tcp::${ORIGINAL_PORT}-:22"* ]]; then
                    QEMU_CMD[$i]="user,model=virtio-net-pci,hostfwd=tcp::${SSH_PORT}-:22"
                fi
            done
            break
        fi
    done

    if [ "$SSH_PORT" -eq "$ORIGINAL_PORT" ]; then
        die "Could not find an available port between $SSH_PORT and $((SSH_PORT + 100))"
    fi
fi

info "Boot method: UEFI firmware → systemd-boot → UKI"
info "Console: Virtio console (this terminal)"
info "SSH: ssh -p $SSH_PORT root@localhost"
info "To quit: Press Ctrl-A X (or Ctrl-C)"
echo ""
warn "Note: Boot may take 15-30 seconds. Watch for systemd boot messages."
echo ""
echo -e "${YELLOW}Press Enter to start...${NC}"
read -r

# Execute QEMU
exec "${QEMU_CMD[@]}"
