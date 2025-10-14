# Fedora 42 - Level 1 Baseline Hardening

Production-ready Fedora 42 image with CIS Benchmark Level 1 security baseline.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (71 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 212 packages
- Image size: 520.0 MB compressed

## Quick Start

```bash
# Build from repository root
./scripts/build-level.sh 1 --os f42

# Or build directly
mkosi -C configs/level-1-minimal/f42 -f build

# Boot with QEMU
mkosi -C configs/level-1-minimal/f42 qemu

# Login: Requires SSH key or password (root account locked by default)

# Enter shell without booting
mkosi -C configs/level-1-minimal/f42 shell
```

## Fedora 42 Specifics

### Package Manager
- **dnf5** - Default in Fedora 42+
- Uses `dnf-automatic.timer` for security updates
- Behavior: Auto-apply security patches daily

### Repository Configuration
- Uses standard Fedora 42 repositories
- No subscription required
- Automated security updates enabled

### SELinux Policy
- `selinux-policy-targeted` - Standard Fedora policy
- Enforcing mode by default
- Comprehensive audit logging enabled

### Kernel
- Standard Fedora 42 kernel
- `kernel-modules-extra` included
- Hardened sysctl parameters applied

### Production Services
- **SSH server** (openssh-server) - Key-based auth, hardened config
- **Audit daemon** (audit) - 40+ CIS-aligned rules
- **File integrity** (aide) - Daily scans
- **System logging** (rsyslog) - Enhanced logging
- **Process accounting** (psacct) - Track command execution
- **Automated updates** (dnf-automatic) - Security patches only

## Requirements

- **mkosi**: >= 25 (tested with 26~devel)
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~4-5 GB for build cache + output
- **SSH keys**: For authentication (or set RootPassword)

## Known Issues

### Issue: Root Account Locked by Default
**Symptom**: Cannot log in after first boot
**Cause**: Production baseline uses locked root account
**Workaround**: Either:
1. Add SSH key to `mkosi.extra/root/.ssh/authorized_keys` before build
2. Or set `RootPassword=YourPassword` in `mkosi.conf`

### Issue: AIDE Database Not Initialized
**Symptom**: AIDE timer fails, no integrity checks
**Cause**: AIDE requires manual initialization on first boot
**Workaround**: After first boot, run:
```bash
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

### Issue: First Boot Delay
**Symptom**: First boot takes 20-40 seconds
**Cause**: SELinux relabeling + service initialization
**Workaround**: Normal behavior; subsequent boots are fast (~6-7 seconds)

## Troubleshooting

### Cannot SSH into system
**Problem**: Locked root account, no keys configured
**Solution**: Set password in `mkosi.conf`:
```ini
RootPassword=YourStrongPassword
```
Or add SSH keys to `mkosi.extra/root/.ssh/authorized_keys`

### Build fails with "package not found"
**Problem**: Production package not available in F42
**Solution**: Check package availability:
```bash
dnf --releasever=42 search aide audit psacct
```

### Audit daemon fails to start
**Problem**: Audit rules syntax error
**Solution**: Check `mkosi.postinst` audit rules configuration

### dnf-automatic timer not enabled
**Problem**: Automated updates not running
**Solution**: Verify timer enabled:
```bash
systemctl is-enabled dnf-automatic.timer
```

## Development Notes

### SSH Key Setup

Create SSH key directory before building:
```bash
mkdir -p configs/level-1-minimal/f42/mkosi.extra/root/.ssh
chmod 700 configs/level-1-minimal/f42/mkosi.extra/root/.ssh

# Add your public key
cat ~/.ssh/id_rsa.pub > configs/level-1-minimal/f42/mkosi.extra/root/.ssh/authorized_keys
chmod 600 configs/level-1-minimal/f42/mkosi.extra/root/.ssh/authorized_keys
```

### Password-Based Authentication (Not Recommended)

For testing only, edit `mkosi.conf`:
```ini
# Development/testing password (INSECURE!)
RootPassword=test

# Production password
RootPassword=YourComplexPassword123!
```

Then enable password auth in SSH config (edit `mkosi.postinst`).

### Firewall Customization

Add services in `mkosi.postinst`:
```bash
# Allow HTTP
firewall-cmd --permanent --zone=public --add-service=http

# Allow custom port
firewall-cmd --permanent --zone=public --add-port=8080/tcp
```

### CIS Benchmark Compliance

Level 1 implements CIS Benchmark Level 1 - Server:
- Section 1: Filesystem configuration
- Section 3: Network parameters (sysctl)
- Section 4: Logging and auditing (auditd + rsyslog)
- Section 5: Access control (SSH, PAM, sudo)
- Section 6: System maintenance (updates, AIDE)

## Resources

- Fedora 42 Release Notes: https://docs.fedoraproject.org/
- CIS Benchmark: https://www.cisecurity.org/benchmark/distribution_independent_linux
- mkosi Documentation: https://github.com/systemd/mkosi
- OpenSCAP Fedora Guide: https://static.open-scap.org/ssg-guides/ssg-fedora-guide-index.html
