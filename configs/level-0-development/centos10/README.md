# CentOS Stream 10 - Level 0 Development

Minimal CentOS Stream 10 image for local development and mkosi experimentation.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (100 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 304.5 MB compressed

**CentOS Stream 10 Status**: Released December 2024, actively maintained

## Quick Start

```bash
# Build from repository root (no subscription needed)
./scripts/build-level.sh 0 --os centos10

# Or build directly
mkosi -C configs/level-0-development/centos10 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/centos10 qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/centos10 shell
```

## CentOS Stream 10 Specifics

### What is CentOS Stream?
- **Upstream development** for RHEL (features land here before RHEL)
- **Rolling release** within major version (Stream 10)
- **Community-driven** distribution
- **No subscription required** - uses public repositories

### Relationship to RHEL
- CentOS Stream 10 → feeds into → RHEL 10.x releases
- Preview of upcoming RHEL 10 features
- Slightly ahead of RHEL in package versions
- Development phase alongside RHEL 10 beta

### Package Manager
- **dnf5** - NEW default in Stream 10 (like Fedora 40+)
- Uses consolidated timer: `dnf-automatic.timer`
- Behavior controlled by `/etc/dnf/automatic.conf`

### Repository Configuration
- **Public repositories** - no subscription needed
- Uses CentOS mirrors
- No mkosi.sandbox/ setup required (unlike RHEL)
- May have beta/development repositories

### SELinux Policy
- `selinux-policy-targeted` - CentOS Stream 10 policy
- Enforcing mode by default
- May have updates during development cycle

### Kernel
- **CentOS Stream 10 kernel** - Based on newer upstream than Stream 9
- Expected base: 6.x series (vs Stream 9's 5.14)
- Development phase - expect kernel updates
- Enterprise-grade stability focus

## Requirements

- **mkosi**: >= 25 (tested with 26~devel)
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~3-4 GB for build cache + output
- **No subscription**: Public repositories

## Known Issues

### Issue: Mirror Availability
**Symptom**: Build fails with repository/mirror errors
**Cause**: CentOS mirrors may have sync delays or availability issues
**Workaround**: Retry build, or wait for mirrors to sync

### Issue: Package Names Changed
**Symptom**: Package not found errors during build
**Cause**: Stream 10 package reorganization or renames
**Workaround**: Check Stream 10 package search, adjust `mkosi.conf`

### Issue: First Boot Delay
**Symptom**: First boot takes 20-40 seconds
**Cause**: SELinux relabeling
**Workaround**: Normal behavior; subsequent boots are fast

### Issue: DNF5 Changes
**Symptom**: dnf-automatic-install.timer not found
**Cause**: Stream 10 uses DNF5 with single timer `dnf-automatic.timer`
**Workaround**: Use `dnf-automatic.timer` only (not -install variant)

## Troubleshooting

### Build fails with "package not found"
**Problem**: Package name different from Stream 9 or not available
**Solution**: Check CentOS Stream 10 packages:
```bash
dnf --releasever=10-stream search <package-name>
```

### Build fails with repository errors
**Problem**: Stream 10 repositories not available or unstable
**Solution**: Wait for Stream 10 GA, use Stream 9 for stable development

### Cannot boot in QEMU
**Problem**: OVMF firmware not found or kernel regression
**Solution**: Install OVMF (`sudo dnf install edk2-ovmf`), check Stream 10 bug tracker

## Development Notes

### CentOS Stream 10 vs Stream 9 Differences

**Major changes:**
- **dnf5** - New package manager (from Fedora)
- **Newer kernel** - 6.x base vs 5.14
- **Updated Python** - Python 3.11+ (vs 3.9)
- **systemd updates** - Newer systemd version
- **New features** - Features from Fedora 40-42

**Package versions:**
- More modern than Stream 9
- Still conservative vs Fedora
- Long-term support planned

### Why Use CentOS Stream 10?

**Use CentOS Stream 10 for:**
- Testing next-gen RHEL features
- Early adoption of RHEL 10 capabilities
- Preview of upcoming enterprise Linux
- Development targeting future RHEL

**Consider CentOS Stream 9 instead for:**
- Existing Stream 9 infrastructure
- More conservative update cycle
- Applications not yet tested on Stream 10

### CentOS Stream 10 Release Information

CentOS Stream 10 (codename "Coughlan") released December 2024:
- **Release Date**: December 12, 2024
- **Kernel**: Linux 6.12
- **Lifecycle**: ~5 years (until ~2030, contingent on RHEL 10)
- **Major Updates**: GCC 14.2.1 (vs 11.5), Python 3.12 (vs 3.9), Wayland default
- **Status**: Production-ready, actively maintained

### CentOS Stream vs RHEL

**Similarities:**
- Same package base (mostly)
- Same SELinux policies
- Same system architecture
- Binary compatible for most purposes

**Differences:**
- **No subscription** required for CentOS Stream
- **Public repositories** (easier builds with mkosi)
- **Slightly ahead** of RHEL in updates
- **Community support** vs enterprise support

## Resources

- CentOS Stream: https://www.centos.org/centos-stream/
- CentOS Package Search: https://pkgs.org/search/?q=&d=centos_stream_10
- EPEL Repository: https://docs.fedoraproject.org/en-US/epel/
- mkosi Documentation: https://github.com/systemd/mkosi
