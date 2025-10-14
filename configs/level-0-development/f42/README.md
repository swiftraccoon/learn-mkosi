# Fedora 42 - Level 0 Development

Minimal Fedora 42 image for local development and mkosi experimentation.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (65 seconds)
- Boot: Verified (UEFI + systemd-boot + UKI)
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 515.4 MB compressed

## Quick Start

```bash
# Build from repository root
./scripts/build-level.sh 0 --os f42

# Or build directly
mkosi -C configs/level-0-development/f42 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/f42 qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/f42 shell
```

## Fedora 42 Specifics

### Package Manager
- **dnf5** - Default in Fedora 42+
- Uses consolidated timer: `dnf-automatic.timer` (not `-install` variant)
- systemd-boot-unsigned bootloader package

### Repository Configuration
- Uses standard Fedora 42 repositories
- No subscription required
- Fast mirrors via mirrorlist

### SELinux Policy
- `selinux-policy-targeted` - Standard Fedora policy
- Enforcing mode by default
- First boot performs automatic relabeling (~15-30 seconds)

### Kernel
- Standard Fedora kernel package
- `kernel-modules-extra` included for crypto/network filesystems
- `microcode_ctl` for CPU firmware updates

## Requirements

- **mkosi**: >= 25 (tested with 26~devel)
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~3-4 GB for build cache + output

## Known Issues

### Issue: First Boot Delay
**Symptom**: First boot takes 15-30 seconds before login prompt
**Cause**: SELinux relabeling on initial boot
**Workaround**: Wait for relabeling to complete; subsequent boots are fast (~5-6 seconds)

### Issue: Build Cache Size
**Symptom**: Build cache grows large over time
**Cause**: dnf keeps package cache
**Workaround**: Periodically clean with `mkosi -C configs/level-0-development/f42 clean`

## Troubleshooting

### Build fails with "package not found"
**Problem**: Fedora 42 package name changed or removed
**Solution**: Check if package exists in F42:
```bash
dnf --releasever=42 search <package-name>
```

### Cannot boot in QEMU
**Problem**: OVMF firmware not found
**Solution**: Install UEFI firmware:
```bash
sudo dnf install edk2-ovmf
```

### Passwordless login doesn't work
**Problem**: Build didn't apply passwordless root config
**Solution**: Verify `mkosi.conf` has `RootPassword=hashed:` (empty hash)

## Development Notes

### Adding Packages
Edit `mkosi.conf` under `[Content]` section:
```ini
Packages=
    # ... existing ...
    git
    python3-pip
```

### Customizing Hostname
Edit `mkosi.conf`:
```ini
Hostname=my-custom-hostname
```

### Network Configuration
NetworkManager is included by default. To configure:
```bash
# Inside VM or via mkosi shell
nmcli connection modify <connection> ipv4.method manual ipv4.addresses 192.168.1.100/24
```

## Resources

- Fedora 42 Release Notes: https://docs.fedoraproject.org/
- mkosi Documentation: https://github.com/systemd/mkosi
- Fedora Package Search: https://packages.fedoraproject.org/
