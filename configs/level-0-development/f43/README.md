# Fedora 43 - Level 0 Development

Minimal Fedora 43 image for local development and mkosi experimentation.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (74 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 522.9 MB compressed

## Quick Start

```bash
# Build from repository root
./scripts/build-level.sh 0 --os f43

# Or build directly
mkosi -C configs/level-0-development/f43 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/f43 qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/f43 shell
```

## Fedora 43 Specifics

### Package Manager
- **dnf5** - Default in Fedora 40+
- Uses consolidated timer: `dnf-automatic.timer`
- Behavior controlled by `/etc/dnf/automatic.conf`

### Repository Configuration
- Uses standard Fedora 43 repositories
- No subscription required
- Mirrors via Fedora mirrorlist

### SELinux Policy
- `selinux-policy-targeted` - Standard Fedora policy
- Enforcing mode by default
- First boot performs automatic relabeling

### Kernel
- Fedora 43 kernel (newer than F42)
- `kernel-modules-extra` for additional drivers
- `microcode_ctl` for Intel/AMD microcode

## Requirements

- **mkosi**: >= 25 (tested with 26~devel)
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~3-4 GB for build cache + output

## Known Issues

### Issue: First Boot Delay
**Symptom**: First boot takes 15-30 seconds
**Cause**: SELinux relabeling
**Workaround**: Normal behavior; subsequent boots are fast

### Issue: Newer Kernel May Have Regressions
**Symptom**: Hardware or driver issues not present in F42
**Cause**: F43 uses newer kernel version
**Workaround**: Monitor Fedora bug tracker, consider F42 for stability

## Troubleshooting

### Build fails with dependency errors
**Problem**: F43 package dependencies changed
**Solution**: Check F43 package availability:
```bash
dnf --releasever=43 search <package-name>
```

### QEMU boot hangs
**Problem**: Kernel regression or OVMF compatibility
**Solution**: Try F42 or file Fedora bug if reproducible

### Passwordless login doesn't work
**Problem**: Build configuration issue
**Solution**: Verify `mkosi.conf` has `RootPassword=hashed:`

## Development Notes

### Adding Packages
Edit `mkosi.conf` under `[Content]`:
```ini
Packages=
    # ... existing ...
    development-package
```

### Using Latest Fedora Features
F43 includes newer versions of core packages - useful for testing bleeding-edge features.

### Package Differences from F42
Most packages identical, but check for:
- Newer systemd version
- Updated Python 3.x
- Latest kernel features

## Resources

- Fedora 43 Release Notes: https://docs.fedoraproject.org/
- mkosi Documentation: https://github.com/systemd/mkosi
- Fedora Package Search: https://packages.fedoraproject.org/
