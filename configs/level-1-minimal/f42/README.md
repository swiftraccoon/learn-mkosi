# Level 1: Minimal Configuration

Baseline security configuration for development and learning.

## Quick Start

```bash
# Build the image (from repo root)
scripts/build-level.sh 1

# Or build directly with mkosi
mkosi -C configs/level-1-minimal/f42 -f build

# Boot with QEMU (direct script - faster)
scripts/run-qemu.sh 1

# Or boot with mkosi wrapper
mkosi -C configs/level-1-minimal/f42 qemu

# Enter a shell
mkosi -C configs/level-1-minimal/f42 shell
```

## Security Features

- SELinux enforcing (targeted policy)
- Firewalld enabled (restrictive defaults)
- Minimal package set (~150-200 packages)
- Basic kernel hardening (sysctl)
- No unnecessary services
- Core dumps disabled
- systemd-boot + UKI for secure boot path

## What's Included

- Kernel and systemd init
- Essential utilities (coreutils, util-linux, bash, etc.)
- Network management (NetworkManager)
- Package manager (dnf, rpm)
- Basic firewall (firewalld)
- Minimal text editor (vim-minimal)
- NTP client (chrony)
- CPU microcode updates
- SELinux policy and tools
- Cryptsetup for encrypted volumes
- CA certificates and SSL support

## What's NOT Included

- Secure Boot signing (Level 2+)
- dm-verity (Level 2+)
- Audit logging (Level 2+)
- Intrusion prevention (Level 2+)
- FIPS mode (Level 3)
- TPM integration (Level 3)
- SSH server (can be added if needed)

## Use Cases

- Development environments
- Learning mkosi and Fedora
- Base for customization
- Low-risk internal systems
- Container host systems

## Configuration Details

### Partition Layout

- **ESP** (512 MB): EFI System Partition with systemd-boot
- **Root** (2-8 GB): ext4 filesystem with automatic growth

### Boot Process

1. UEFI firmware loads systemd-boot from ESP
2. systemd-boot loads UKI (Unified Kernel Image)
3. UKI contains kernel + initrd + command line
4. systemd starts as init system

### Kernel Command Line

```
rw console=hvc0
```

- `rw`: Mount root filesystem read-write
- `console=hvc0`: Output to virtio console (for QEMU)

## Customization

Edit `mkosi.conf` to add packages or change configuration.

For local overrides, create `mkosi.local.conf`:

```ini
[Content]
Packages=
    your-additional-package
```

## Testing

After building, verify security configuration:

```bash
# Check SELinux
mkosi -C configs/level-1-minimal/f42 shell -- getenforce

# Check firewall
mkosi -C configs/level-1-minimal/f42 shell -- firewall-cmd --list-all

# Count packages
mkosi -C configs/level-1-minimal/f42 shell -- rpm -qa | wc -l

# Check systemd status
mkosi -C configs/level-1-minimal/f42 shell -- systemctl status
```

## Fedora 42 Specific Notes

### Build Status

✅ Build successful (tested 2025-10-13)
✅ Boot verified (UEFI with systemd-boot + UKI)
✅ Boots to login prompt

**Build Metrics:**
- Compressed image: ~534 MB
- Uncompressed image: ~2.5 GB
- Package count: ~191 packages
- Build time: ~60-70 seconds (with cache)

### Known Issues

- First boot may take 15-30 seconds for systemd initialization
- SELinux relabeling adds ~5-10 seconds to first boot
- Build warnings about cryptsetup slices (non-fatal)

### Requirements

- mkosi >= 25 (tested with 26~devel)
- systemd-boot-unsigned package
- OVMF firmware for UEFI boot
- 2GB+ RAM for QEMU

## Build Artifacts

After building, you'll find in `mkosi.output/`:

- `fedora-minimal-level1_1.0.raw.zst` - Compressed disk image
- `fedora-minimal-level1_1.0.efi` - UKI (Unified Kernel Image)
- `fedora-minimal-level1_1.0.vmlinuz` - Kernel
- `fedora-minimal-level1_1.0.initrd` - Initramfs

## Troubleshooting

### Boot Issues

If the VM hangs during boot:
- Check kernel command line in UKI
- Verify root partition has files: `mount image.raw && ls`
- Ensure `CopyFiles=/` is in `mkosi.repart/10-root.conf`

### Build Failures

- Review logs in `logs/` directory
- Check `scripts/build-level.sh 1` output
- Verify mkosi version: `mkosi --version`

## Next Steps

- Review [SECURITY-LEVELS.md](../../../docs/SECURITY-LEVELS.md) for hardening options
- See Level 2 for production-ready security