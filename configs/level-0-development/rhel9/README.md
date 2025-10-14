# RHEL 9 - Level 0 Development

Minimal Red Hat Enterprise Linux 9 image for local development and mkosi experimentation.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (72 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 303.7 MB compressed

## Quick Start

```bash
# Build from repository root (requires subscription)
./scripts/build-level.sh 0 --os rhel9

# Or build directly
mkosi -C configs/level-0-development/rhel9 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/rhel9 qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/rhel9 shell
```

## RHEL 9 Specifics

### Subscription Requirement
**RHEL requires a valid subscription to access packages**, even for development.

Red Hat provides **free** RHEL for developers:
- **No-cost RHEL Developer Subscription**
- Up to **16 systems** for development use
- Register at: https://developers.redhat.com/

### Setting Up Subscription for mkosi

mkosi needs access to subscription certificates. This repository includes `mkosi.sandbox/` with the required certificates.

**If you don't have certificates yet**:

1. Register your system:
```bash
sudo subscription-manager register --username your-rh-username
```

2. Copy certificates to mkosi.sandbox:
```bash
# From repository root
cd configs/level-0-development/rhel9

# Copy subscription certificates
sudo cp -r /etc/rhsm/ca mkosi.sandbox/etc/rhsm/
sudo cp -r /etc/pki/entitlement mkosi.sandbox/etc/pki/
sudo cp -r /etc/pki/consumer mkosi.sandbox/etc/pki/

# Fix ownership
sudo chown -R $USER:$USER mkosi.sandbox/
```

3. Build as normal:
```bash
./scripts/build-level.sh 0 --os rhel9
```

### Package Manager
- **dnf/yum** - Traditional package manager (RHEL 9 uses dnf)
- No dnf5 yet (comes in RHEL 10+)
- Uses `dnf-automatic` for automated updates

### Repository Configuration
- Requires active subscription
- Uses Red Hat CDN repositories
- Simple Content Access (SCA) mode - automatic entitlements

### SELinux Policy
- `selinux-policy-targeted` - Standard RHEL policy
- Enforcing mode by default
- More conservative than Fedora (slower to adopt changes)

### Kernel
- **RHEL 9 kernel** - Enterprise-grade, stable
- Based on older upstream (5.14 base for RHEL 9)
- Extensive backports for stability
- Long-term support lifecycle

## Requirements

- **Red Hat subscription** (free for developers)
- **mkosi**: >= 25 (tested with 26~devel)
- **Subscription certificates** in `mkosi.sandbox/`
- **QEMU/OVMF**: For UEFI boot testing
- **RAM**: 2GB minimum for QEMU
- **Disk**: ~3-4 GB for build cache + output

## Known Issues

### Issue: Build Fails with "redhat-uep.pem certificate not found"
**Symptom**: mkosi cannot access Red Hat repositories
**Cause**: Subscription certificates not available to mkosi
**Workaround**: Copy certificates to `mkosi.sandbox/` as shown above

### Issue: Subscription Manager Registration Fails
**Symptom**: Cannot register system
**Cause**: Network issues, wrong credentials, or already registered
**Workaround**:
```bash
# Check if already registered
sudo subscription-manager status

# Unregister if needed
sudo subscription-manager unregister

# Re-register
sudo subscription-manager register --username your-username
```

### Issue: First Boot Delay
**Symptom**: First boot takes 20-40 seconds
**Cause**: SELinux relabeling
**Workaround**: Normal behavior; subsequent boots are fast

## Troubleshooting

### Build fails with "package not found"
**Problem**: Package name different in RHEL vs Fedora
**Solution**: Check RHEL 9 package names:
```bash
dnf --releasever=9 search <package-name>
```

### Build fails with subscription errors
**Problem**: Subscription certificates expired or invalid
**Solution**:
1. Verify subscription status: `sudo subscription-manager status`
2. Refresh certificates: `sudo subscription-manager refresh`
3. Re-copy certificates to `mkosi.sandbox/`

### Cannot access Red Hat repositories
**Problem**: Subscription not attached
**Solution**: Red Hat uses Simple Content Access - just register, no manual attachment needed

## Development Notes

### RHEL vs Fedora Differences

**Package versions:**
- Much older than Fedora (stability focus)
- Python 3.9 (vs Fedora's 3.12+)
- systemd 252 (vs Fedora's 255+)
- Kernel 5.14 base (vs Fedora's 6.x)

**Package names:**
- Most are the same as Fedora
- Some differences in Optional/HA repositories

**Lifecycle:**
- 10-year support lifecycle
- Regular minor releases (9.0, 9.1, 9.2, etc.)
- Focus on stability over latest features

### Why Use RHEL 9?

**Use RHEL 9 for:**
- Enterprise environment compatibility
- Testing RHEL-specific behaviors
- Long-term stability requirements
- CentOS/Fedora → RHEL migration testing

**Don't use RHEL 9 for:**
- Latest kernel features (use Fedora)
- Bleeding-edge package versions
- Experimentation with new tech
- Non-enterprise development

### Free Developer Subscription Details

Red Hat provides no-cost RHEL for developers:
- **16 systems** for development/testing
- Same binaries as paid subscriptions
- Access to all repositories
- Not for production use
- Register at: https://developers.redhat.com/

## Resources

- RHEL Developer Program: https://developers.redhat.com/
- RHEL 9 Documentation: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9
- Subscription Manager Guide: https://access.redhat.com/documentation/en-us/subscription_central/
- mkosi Documentation: https://github.com/systemd/mkosi
