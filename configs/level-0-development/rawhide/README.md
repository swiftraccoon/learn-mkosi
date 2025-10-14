# Fedora Rawhide - Level 0 Development

Minimal Fedora Rawhide image for bleeding-edge development and mkosi testing.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (75 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 523.7 MB compressed

NOTE: Rawhide is the development branch - expect occasional breakage.

## Quick Start

```bash
# Build from repository root
./scripts/build-level.sh 0 --os rawhide

# Or build directly
mkosi -C configs/level-0-development/rawhide -f build

# Boot with QEMU
mkosi -C configs/level-0-development/rawhide qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/rawhide shell
```

## Fedora Rawhide Specifics

### What is Rawhide?
- **Development branch** of Fedora (eventually becomes next Fedora release)
- **Rolling release** - constantly updated with latest packages
- **Bleeding edge** - newest kernels, systemd, toolchains
- **Unstable** - May have bugs, incompatibilities, breakage

### Package Manager
- **dnf5** - Latest development version
- Uses `dnf-automatic.timer` for automated updates
- Package churn is high - rebuild frequently

### Repository Configuration
- Uses Fedora Rawhide repositories
- No version pinning - always latest
- Repo metadata updates frequently

### SELinux Policy
- `selinux-policy-targeted` - Development version
- May have policy issues with new packages
- First boot performs relabeling

### Kernel
- **Latest upstream kernel** (may include RC kernels)
- Newest features and drivers
- Potential for regressions or boot failures

## Requirements

- **mkosi**: >= 25 (tested with 26~devel)
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~3-4 GB for build cache + output
- **Patience**: Rawhide can be unstable

## Known Issues

### Issue: Build Failures During Rawhide Freeze
**Symptom**: Package dependency conflicts during build
**Cause**: Rawhide package transitions (new Python, glibc, etc.)
**Workaround**: Wait 1-2 days, retry build after repository stabilizes

### Issue: Boot Failures After Kernel Update
**Symptom**: Kernel panic or boot hangs
**Cause**: Regression in latest kernel
**Workaround**: Check Fedora bug tracker, pin to older kernel version temporarily

### Issue: SELinux Denials
**Symptom**: Services fail due to SELinux policy denials
**Cause**: Policy hasn't caught up to package changes
**Workaround**: Check audit logs, file bug or use F43 for stability

### Issue: systemd Breaking Changes
**Symptom**: Boot configuration or services fail
**Cause**: systemd development changes
**Workaround**: Monitor systemd mailing list, expect fixes in days

## Troubleshooting

### Build fails with "package not found"
**Problem**: Package renamed or removed in Rawhide
**Solution**: Check Rawhide package search, find replacement:
```bash
dnf --releasever=rawhide search <package-name>
```

### Build fails with dependency conflicts
**Problem**: Rawhide package transition (Python, glibc, GCC upgrade)
**Solution**: Wait 24-48 hours for repository to stabilize, then retry

### Cannot boot - kernel panic
**Problem**: Bleeding-edge kernel regression
**Solution**:
1. Check Fedora bug tracker
2. Use F43 for stable development
3. Wait for kernel fix (usually days)

### systemd service fails to start
**Problem**: systemd API or behavior changed
**Solution**: Check systemd journal, may need config adjustments

## Development Notes

### Why Use Rawhide?

**Use Rawhide for:**
- Testing code against upcoming Fedora release
- Trying latest kernel features
- Development of Fedora packages
- Finding bugs before they reach stable releases
- Experimenting with bleeding-edge tech

**Don't use Rawhide for:**
- Stable development work (use F42 or F43)
- Production testing
- Critical deadlines
- Learning mkosi basics

### Rebuild Frequency
Rawhide changes rapidly. Rebuild regularly:
```bash
# Rebuild daily to stay current
./scripts/build-level.sh 0 --os rawhide -f
```

### Package Differences from F43
- **Kernel**: Often 1-2 versions ahead
- **systemd**: Development branch
- **Python**: May be newer version (3.13, 3.14, etc.)
- **GCC/toolchain**: Latest compiler versions

## Resources

- Fedora Rawhide Status: https://fedoraproject.org/wiki/Releases/Rawhide
- Rawhide Report (daily status): https://fedoraproject.org/wiki/Rawhide
- mkosi Documentation: https://github.com/systemd/mkosi
- Fedora Bug Tracker: https://bugzilla.redhat.com/
