# CentOS Stream 9 - Level 0 Development

Minimal CentOS Stream 9 image for local development and mkosi experimentation.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (128 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 307.4 MB compressed

## Quick Start

```bash
# Build from repository root (no subscription needed)
./scripts/build-level.sh 0 --os centos9

# Or build directly
mkosi -C configs/level-0-development/centos9 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/centos9 qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/centos9 shell
```

## CentOS Stream 9 Specifics

### What is CentOS Stream?
- **Upstream development** for RHEL (features land here before RHEL)
- **Rolling release** within major version (Stream 9)
- **Community-driven** distribution
- **No subscription required** - uses public repositories

### Relationship to RHEL
- CentOS Stream 9 → feeds into → RHEL 9.x releases
- Slightly ahead of RHEL in package versions
- Similar stability to Fedora stable releases
- Preview of upcoming RHEL features

### Package Manager
- **dnf/yum** - Traditional package manager
- No dnf5 yet (comes in Stream 10)
- Uses `dnf-automatic` for automated updates

### Repository Configuration
- **Public repositories** - no subscription needed
- Uses CentOS mirrors
- No mkosi.sandbox/ setup required (unlike RHEL)

### SELinux Policy
- `selinux-policy-targeted` - Same as RHEL 9
- Enforcing mode by default
- Compatible with RHEL 9 policies

### Kernel
- **CentOS Stream 9 kernel** - Based on RHEL 9 kernel (5.14 base)
- Receives updates before RHEL minor releases
- Enterprise-grade stability
- Extensive backports

## Requirements

- **mkosi**: >= 25 (tested with 26~devel)
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~3-4 GB for build cache + output
- **No subscription**: Public repositories

## Known Issues

### Issue: First Boot Delay
**Symptom**: First boot takes 20-40 seconds
**Cause**: SELinux relabeling
**Workaround**: Normal behavior; subsequent boots are fast

### Issue: Package Availability
**Symptom**: Some Fedora packages not available
**Cause**: CentOS Stream has conservative package selection
**Workaround**: Check CentOS Stream repositories, may need EPEL

## Troubleshooting

### Build fails with "package not found"
**Problem**: Package name different from Fedora or not available
**Solution**: Check CentOS Stream 9 packages:
```bash
dnf --releasever=9-stream search <package-name>
```

### Cannot boot in QEMU
**Problem**: OVMF firmware not found
**Solution**: Install UEFI firmware:
```bash
sudo dnf install edk2-ovmf
```

### Passwordless login doesn't work
**Problem**: Build configuration issue
**Solution**: Verify `mkosi.conf` has `RootPassword=hashed:`

## Development Notes

### CentOS Stream vs Fedora Differences

**Package versions:**
- Older than Fedora (but newer than RHEL)
- Python 3.9 (vs Fedora's 3.12+)
- systemd 252 (vs Fedora's 255+)
- Kernel 5.14 base (vs Fedora's 6.x)

**Package names:**
- Mostly compatible with Fedora
- Some packages require EPEL (Extra Packages for Enterprise Linux)

**Lifecycle:**
- Supported until RHEL 9 EOL (~2032)
- Regular updates from upstream
- Rolling within major version

### Why Use CentOS Stream 9?

**Use CentOS Stream 9 for:**
- Testing RHEL 9 compatibility without subscription
- Development targeting RHEL environments
- Preview of upcoming RHEL features
- Community-based enterprise Linux development

**Don't use CentOS Stream 9 for:**
- Latest kernel features (use Fedora)
- Bleeding-edge packages (use Fedora Rawhide)
- Experimentation with new tech (use Fedora)

### CentOS Stream vs RHEL

**Similarities:**
- Same package base and versions (mostly)
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
- CentOS Package Search: https://pkgs.org/search/?q=&d=centos_stream_9
- EPEL Repository: https://docs.fedoraproject.org/en-US/epel/
- mkosi Documentation: https://github.com/systemd/mkosi
