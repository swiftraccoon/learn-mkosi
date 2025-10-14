# Quick Start Guide

Get started building minimal, security-hardened Linux images in minutes.

## Prerequisites

**Important**: These configurations require mkosi v26+. See [SETUP.md](SETUP.md) for setup.

```bash
# Verify version (must be v26+, not v25.3)
mkosi --version
# Should show: mkosi 26~devel

# If shows v25.3, add ~/.local/bin to PATH:
export PATH="$HOME/.local/bin:$PATH"
mkosi --version
```

**Quick PATH fix** (if needed):
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Build Your First Image

### Level 0: Development (Recommended for First Try)

```bash
# Build (Fedora 42)
mkosi -C configs/level-0-development/f42 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/f42 qemu

# Login: Just press Enter (passwordless root)

# Or enter a shell
mkosi -C configs/level-0-development/f42 shell
```

### Level 1: Production Baseline

```bash
# Build (Fedora 42)
mkosi -C configs/level-1-minimal/f42 -f build

# Boot with QEMU
mkosi -C configs/level-1-minimal/f42 qemu

# Login: Requires SSH key or password

# Or enter a shell
mkosi -C configs/level-1-minimal/f42 shell
```

### Level 2: Hardened

```bash
# Generate Secure Boot keys
mkosi -C configs/level-2-hardened/f42 genkey

# Build
mkosi -C configs/level-2-hardened/f42 -f build

# Boot
mkosi -C configs/level-2-hardened/f42 qemu
```

### Level 3: Maximum Security

```bash
# Generate keys
mkosi -C configs/level-3-maximum/f42 genkey

# Build (takes longer)
mkosi -C configs/level-3-maximum/f42 -f build

# Boot (requires more RAM)
mkosi -C configs/level-3-maximum/f42 qemu
```

## Using Build Scripts

```bash
# Build specific level (defaults to Fedora 42)
./scripts/build-level.sh 0              # Level 0 Development
./scripts/build-level.sh 1              # Level 1 Baseline
./scripts/build-level.sh 1 --os rhel9   # Level 1 for RHEL 9

# Build all levels for an OS
./scripts/build-all.sh              # All levels for Fedora 42
./scripts/build-all.sh --os rhel9   # All levels for RHEL 9

# Verify security
./scripts/verify-security.sh 0      # Verify Level 0 - Fedora 42
./scripts/verify-security.sh 1 --os rhel9   # Verify Level 1 - RHEL 9
```

## Next Steps

- Read [README.md](README.md) for overview
- Check [SECURITY-LEVELS.md](docs/SECURITY-LEVELS.md) for detailed security analysis
- See [MKOSI-GUIDE.md](docs/MKOSI-GUIDE.md) for customization
- Review [PACKAGE-REFERENCE.md](docs/PACKAGE-REFERENCE.md) for package lists

## Common Commands

```bash
# Clean and rebuild
mkosi -C configs/level-1-minimal/f42 -f clean
mkosi -C configs/level-1-minimal/f42 build

# Force full rebuild (clear cache)
mkosi -C configs/level-1-minimal/f42 -ff build

# Boot with serial console
mkosi -C configs/level-1-minimal/f42 qemu -- -serial mon:stdio -nographic

# SSH into running VM (Level 1+)
mkosi -C configs/level-1-minimal/f42 ssh

# Check configuration summary
mkosi -C configs/level-1-minimal/f42 summary
```

## Troubleshooting

### Build Fails

```bash
# Check mkosi version
mkosi --version  # Need v26+

# Clean everything and retry
mkosi -C configs/level-1-minimal/f42 -fff build

# Check build logs
./scripts/review-logs.sh 1
```

### QEMU Fails to Boot

```bash
# Install OVMF firmware
sudo dnf install edk2-ovmf

# Try with debug output
mkosi -C configs/level-1-minimal/f42 --debug qemu
```

### Permission Errors

```bash
# May need to run with elevated privileges
sudo mkosi -C configs/level-1-minimal/f42 build
```

## What's in Each Level?

| Feature | Level 0 | Level 1 | Level 2 | Level 3 |
|---------|---------|---------|---------|---------|
| Packages | ~191 | ~220-250 | ~250-300 | ~300-400 |
| SSH Server | No | Yes | Yes | Yes |
| Audit Logging | No | Yes | Yes | Yes |
| SELinux | Targeted | Targeted | MLS | MLS |
| Firewall | Basic | Hardened | Hardened | Hardened |
| Secure Boot | No | No | Yes | Yes |
| dm-verity | No | No | Yes (unsigned) | Yes (signed) |
| FIPS Mode | No | No | No | Yes |
| TPM2 | No | No | No | Yes |
| Compliance | No | CIS L1 | CIS L2 | FIPS/OSPP |

## Getting Help

- Review documentation in `docs/`
- Check example configurations in `configs/`
- See systemd hardening examples in `docs/examples/`
- Read [mkosi documentation](https://github.com/systemd/mkosi)

## Next Actions

1. Build Level 0 for development or Level 1 for production
2. Review generated image in `configs/level-X-name/OS/mkosi.output/`
3. Customize `mkosi.conf` for your needs
4. Review [SECURITY-LEVELS.md](docs/SECURITY-LEVELS.md) for level comparison
5. Use Level 2+ when ready for advanced hardening
