# Learn mkosi

Build security-hardened Linux images using mkosi with four security levels from development to maximum hardening.

## Quick Start

```bash
# Build Level 0 (Development)
./scripts/build-level.sh 0

# Boot with QEMU
mkosi -C configs/level-0-development/f42 qemu

# Login: Press Enter (passwordless)
```

For installation instructions, see [QUICKSTART.md](QUICKSTART.md).

## Security Levels

### Level 0: Development/Learning
- 191 packages, passwordless root, no SSH
- Local development only, NOT for production
- Fedora 42/43/Rawhide, RHEL 9/10, CentOS Stream 9/10

### Level 1: Baseline Hardening (Production-Ready)
- 212 packages, SSH with hardening, audit logging, AIDE
- CIS Benchmark Level 1 - Server aligned
- Fedora 42, RHEL 9

### Level 2: Expert Hardening
- Secure Boot, dm-verity, fail2ban, SELinux MLS
- CIS Benchmark Level 2 - Server aligned
- Planned

### Level 3: Maximum Security
- FIPS mode, TPM2, signed images, immutable root
- Compliance (PCI-DSS, OSPP)
- Planned

## Building

```bash
# Build specific level (defaults to Fedora 42)
./scripts/build-level.sh 0
./scripts/build-level.sh 1 --os rhel9

# Boot
mkosi -C configs/level-0-development/f42 qemu
```

## Customization

Edit `configs/level-X/OS/mkosi.conf` to add packages or modify configuration. See OS-specific READMEs in each config directory.

## References

- [mkosi Documentation](https://github.com/systemd/mkosi)
- [systemd Security Hardening](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Sandboxing)
- [Fedora Security Guide](https://docs.fedoraproject.org/en-US/Fedora/20/html/Security_Guide/)
- [OpenSCAP Security Profiles](https://static.open-scap.org/ssg-guides/ssg-fedora-guide-index.html)
- [CIS Benchmarks](https://www.cisecurity.org/benchmark/distribution_independent_linux)
