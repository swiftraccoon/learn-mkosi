# RHEL 10 - Level 0 Development

Minimal Red Hat Enterprise Linux 10 image for local development and mkosi experimentation.

## Build Status

Successfully Built and Tested (2025-10-13)
- Build: Successful (55 seconds)
- Boot: Verified
- SELinux: Enforcing (targeted policy)
- Package count: 191 packages
- Image size: 294.6 MB compressed

**RHEL 10 Status**: GA (General Availability) since May 2025

## Quick Start

```bash
# Build from repository root (requires subscription)
./scripts/build-level.sh 0 --os rhel10

# Or build directly
mkosi -C configs/level-0-development/rhel10 -f build

# Boot with QEMU
mkosi -C configs/level-0-development/rhel10 qemu

# Login: Press Enter (passwordless root)

# Enter shell without booting
mkosi -C configs/level-0-development/rhel10 shell
```

## RHEL 10 Specifics

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
cd configs/level-0-development/rhel10

# Copy subscription certificates
sudo cp -r /etc/rhsm/ca mkosi.sandbox/etc/rhsm/
sudo cp -r /etc/pki/entitlement mkosi.sandbox/etc/pki/
sudo cp -r /etc/pki/consumer mkosi.sandbox/etc/pki/

# Fix ownership
sudo chown -R $USER:$USER mkosi.sandbox/
```

3. Build as normal:
```bash
./scripts/build-level.sh 0 --os rhel10
```

### Package Manager
- **dnf5** - NEW default in RHEL 10 (like Fedora 40+)
- Uses consolidated timer: `dnf-automatic.timer`
- Behavior controlled by `/etc/dnf/automatic.conf`

### Repository Configuration
- Requires active subscription
- Uses Red Hat CDN repositories
- Simple Content Access (SCA) mode - automatic entitlements
- Beta/development repositories during pre-release

### SELinux Policy
- `selinux-policy-targeted` - RHEL 10 policy
- Enforcing mode by default
- May have updates during development cycle

### Kernel
- **RHEL 10 kernel** - Based on newer upstream than RHEL 9
- Expected base: 6.x series (vs RHEL 9's 5.14)
- Development phase - expect kernel updates

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

### Issue: RHEL 10 Subscription Required
**Symptom**: Build fails with repository access errors
**Cause**: RHEL 10 requires valid Red Hat subscription
**Workaround**: Register system and copy certificates to mkosi.sandbox/ (see setup instructions)

### Issue: Package Names Changed
**Symptom**: Package not found errors during build
**Cause**: RHEL 10 package reorganization or renames
**Workaround**: Check RHEL 10 package search, adjust `mkosi.conf`

### Issue: First Boot Delay
**Symptom**: First boot takes 20-40 seconds
**Cause**: SELinux relabeling
**Workaround**: Normal behavior; subsequent boots are fast

## Troubleshooting

### Build fails with "package not found"
**Problem**: Package name different in RHEL 10 vs RHEL 9
**Solution**: Check RHEL 10 package names:
```bash
dnf --releasever=10 search <package-name>
```

### Build fails with subscription errors
**Problem**: Subscription certificates expired or invalid
**Solution**:
1. Verify subscription status: `sudo subscription-manager status`
2. Refresh certificates: `sudo subscription-manager refresh`
3. Re-copy certificates to `mkosi.sandbox/`

### DNF5 timer errors
**Problem**: dnf-automatic-install.timer not found
**Solution**: RHEL 10 uses DNF5 with single timer `dnf-automatic.timer` (not -install variant)

## Development Notes

### RHEL 10 vs RHEL 9 Differences

**Major changes:**
- **dnf5** - New package manager (from Fedora)
- **Newer kernel** - 6.x base vs 5.14
- **Updated Python** - Python 3.11+ (vs 3.9)
- **systemd updates** - Newer systemd version
- **New features** - Features from Fedora 40-42

**Package versions:**
- More modern than RHEL 9
- Still conservative vs Fedora
- 10-year support lifecycle

### Why Use RHEL 10?

**Use RHEL 10 for:**
- Testing next-gen RHEL
- Early adoption of RHEL 10 features
- Migration planning from RHEL 9
- Development targeting future RHEL

**Consider RHEL 9 instead for:**
- Existing RHEL 9 infrastructure
- Applications not yet certified for RHEL 10
- More conservative enterprise requirements

### RHEL 10 Release Information

RHEL 10 (codename "Coughlan") reached GA in May 2025:
- **GA Release**: May 13, 2025 (downloads available)
- **Official Announcement**: May 20, 2025 (Red Hat Summit)
- **Kernel**: Linux 6.12
- **Lifecycle**: 10-year support (Full Support + Extended Life)
- **Status**: Production-ready, fully supported

### Free Developer Subscription Details

Red Hat provides no-cost RHEL for developers:
- **16 systems** for development/testing
- Same binaries as paid subscriptions
- Access to all repositories including beta
- Not for production use
- Register at: https://developers.redhat.com/

## Resources

- RHEL Developer Program: https://developers.redhat.com/
- RHEL 10 Beta Documentation: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/10-beta
- Subscription Manager Guide: https://access.redhat.com/documentation/en-us/subscription_central/
- mkosi Documentation: https://github.com/systemd/mkosi
