# Learn mkosi

A comprehensive repository for building minimal, security-hardened Linux images using mkosi, with four distinct security levels optimized for different use cases - from development to maximum security.

Supports: Fedora 42, Fedora 43, Fedora Rawhide, RHEL 9, RHEL 10, CentOS Stream 9, CentOS Stream 10

## Overview

This project provides ready-to-use mkosi configurations for creating minimal Linux images with varying levels of security hardening. Each configuration is designed to be:

- **Minimal**: Only essential packages installed
- **Secure**: Built-in security hardening at multiple levels
- **Reproducible**: Deterministic builds using mkosi
- **Well-documented**: Clear explanations of choices and trade-offs

## Quick Start

```bash
# Build a specific security level (defaults to Fedora 42)
./scripts/build-level.sh 0           # Level 0 Development - Fedora 42
./scripts/build-level.sh 1           # Level 1 Baseline - Fedora 42
./scripts/build-level.sh 2 --os f42  # Level 2 Hardened - Fedora 42
./scripts/build-level.sh 3 --os rhel9  # Level 3 Maximum - RHEL 9

# Build all levels for an OS (0-3)
./scripts/build-all.sh              # All levels for Fedora 42
./scripts/build-all.sh --os rhel9   # All levels for RHEL 9

# Boot an image with QEMU
mkosi -C configs/level-0-development/f42 qemu  # Development
mkosi -C configs/level-1-minimal/f42 qemu      # Production Baseline
```

## Security Levels

### Level 0: Development/Learning

**Target Use Case**: Local development, learning mkosi, experimentation

**Key Features**:
- ~190-200 packages (kernel, systemd, core utilities)
- SELinux enforcing mode (targeted policy)
- Basic firewall (firewalld)
- systemd-boot bootloader with UKI
- No SSH server (local only)
- **Passwordless root** for development convenience
- Minimal security hardening

**Security Posture**: NOT for production use. Development convenience over security.

WARNING: Never use Level 0 in production or network-accessible systems.

### Level 1: Baseline Hardening (Production-Ready)

**Target Use Case**: General production servers, standard deployments

**Key Features**:
- ~220-250 packages (adds production security tooling)
- SELinux enforcing mode (targeted policy)
- **SSH server with hardening** (key-based auth only)
- **Audit logging** (auditd) with comprehensive rules
- **File integrity monitoring** (AIDE)
- **Automated security updates** (dnf-automatic)
- **Password quality enforcement** (14+ chars, complexity)
- **Locked root account** (requires SSH key)
- Firewalld with restrictive defaults
- CIS Benchmark Level 1 - Server aligned

**Security Posture**: Production baseline security - more secure than standard installations.

### Level 2: Hardened (Expert Hardening)

**Target Use Case**: High-value server deployments, sensitive workloads

**Key Features**:
- Level 1 foundation + expert hardening
- SELinux MLS (Multi-Level Security) policy
- Comprehensive systemd service hardening
- UEFI Secure Boot enabled
- dm-verity for root partition (unsigned)
- Crypto policies set to FUTURE
- Enhanced audit rules
- Fail2ban for intrusion prevention
- Advanced firewall rules
- CIS Benchmark Level 2 - Server aligned

**Security Posture**: Expert hardening - more security than normally seen in production.

### Level 3: Maximum Security

**Target Use Case**: High-security environments, compliance requirements (PCI-DSS, OSPP)

**Key Features**:
- Level 2 foundation + maximum hardening
- FIPS mode enabled
- Signed dm-verity partitions
- Signed Unified Kernel Images (UKI)
- TPM2 PCR policies
- Immutable root filesystem (read-only)
- Aggressive systemd service sandboxing
- Stricter crypto policies
- OpenSCAP compliance scanning
- USBGuard for USB device authorization
- SELinux in strictest mode

**Security Posture**: Strictest possible hardening - exceeding most government requirements.

## Prerequisites

### Required Tools

- mkosi v26 or newer (**Important**: Fedora Rawhide ships v25.3, see [SETUP.md](SETUP.md))
- systemd-repart
- QEMU (for testing)
- Fedora package manager (dnf)
- Python 3.9+

### Installation

**Important**: This repository requires mkosi v26+. Fedora Rawhide currently ships v25.3.

#### Option 1: Use mkosi v26 from Source (Recommended)

A symlink has been created to `references/mkosi/bin/mkosi` (v26~devel):

```bash
# Add ~/.local/bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify version
mkosi --version  # Should show: mkosi 26~devel
```

See [SETUP.md](SETUP.md) for detailed setup instructions.

#### Option 2: System mkosi (Requires v26+)

```bash
# Install mkosi (only if v26+ available)
sudo dnf install mkosi

# Check version
mkosi --version  # Must be 26 or higher
```

## Building Images

### Build a Specific Level

```bash
# Using build-level.sh (recommended)
./scripts/build-level.sh 0              # Level 0 Development - Fedora 42
./scripts/build-level.sh 1              # Level 1 Baseline - Fedora 42
./scripts/build-level.sh 2 --os rhel9   # Level 2 Hardened - RHEL 9
./scripts/build-level.sh 3 -o f42 -f    # Level 3 Maximum - Fedora 42 (force rebuild)

# Or directly with mkosi
mkosi -C configs/level-0-development/f42 -f build
mkosi -C configs/level-1-minimal/f42 -f build
mkosi -C configs/level-2-hardened/rhel9 -f build 
mkosi -C configs/level-3-maximum/f42 -f build
```

### Boot and Test

```bash
# Boot with QEMU (via mkosi wrapper)
mkosi -C configs/level-0-development/f42 qemu  # Development
mkosi -C configs/level-1-minimal/f42 qemu      # Production Baseline

# Or use direct QEMU script (faster, more control)
./scripts/run-qemu.sh 0              # Level 0 - Fedora 42
./scripts/run-qemu.sh 1              # Level 1 - Fedora 42
./scripts/run-qemu.sh 2 --os rhel9   # Level 2 - RHEL 9
./scripts/run-qemu.sh 3 --memory 4096  # Level 3 with 4GB RAM

# Enter a shell in the image
mkosi -C configs/level-0-development/f42 shell  # Development
mkosi -C configs/level-1-minimal/f42 shell      # Production Baseline

# SSH into a running VM (Level 1+)
mkosi -C configs/level-1-minimal/f42 ssh
# Or if started with run-qemu.sh:
ssh -p 10022 root@localhost
```

## Customization

Each security level can be customized by modifying the configuration files in `configs/level-X/OS/`:

- `mkosi.conf`: Main configuration (packages, options)
- `mkosi.repart/`: Partition layout definitions
- `mkosi.extra/`: Additional files to include in the image
- `mkosi.postinst`: Post-installation script

Example: To customize Level 1 for Fedora 42, edit files in `configs/level-1-minimal/f42/`

## Security Verification

Run the security verification script to check the security posture of built images:

```bash
./scripts/verify-security.sh 0              # Verify Level 0 - Fedora 42 (basic checks)
./scripts/verify-security.sh 1              # Verify Level 1 - Fedora 42 (production checks)
./scripts/verify-security.sh 2 --os rhel9   # Verify Level 2 - RHEL 9
./scripts/verify-security.sh 3 -o f42       # Verify Level 3 - Fedora 42
```

## Common Tasks

### Add a Package

Edit the `Packages=` section in `configs/level-X/OS/mkosi.conf`:

```ini
[Content]
Packages=
    existing-package
    your-new-package
```

Example: `configs/level-1-minimal/f42/mkosi.conf`

### Enable a systemd Service

Create a file in `mkosi.extra/etc/systemd/system/`:

```bash
# Example: configs/level-1-minimal/f42/mkosi.extra/etc/systemd/system/your-service.service
```

Or use a post-installation script in `mkosi.postinst`.

### Change Kernel Parameters

Edit the `KernelCommandLineExtra=` option in `mkosi.conf` or modify the bootloader configuration in `mkosi.extra/`.

## References

- [mkosi Documentation](https://github.com/systemd/mkosi)
- [systemd Security Hardening](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing)
- [Fedora Security Guide](https://docs.fedoraproject.org/en-US/Fedora/20/html/Security_Guide/)
- [OpenSCAP Security Profiles](https://static.open-scap.org/ssg-guides/ssg-fedora-guide-index.html)
