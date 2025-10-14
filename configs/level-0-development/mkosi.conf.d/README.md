# Level 0 Drop-in Configuration

This directory contains mkosi drop-in configuration files that customize the base `mkosi.conf` for specific distributions and releases.

## Structure

- `mkosi.conf` (parent directory) - Base configuration shared across all OS variants
- `mkosi.postinst` (parent directory) - Shared post-installation script
- `mkosi.repart/` (parent directory) - Shared partition definitions

### Drop-in Files

**Distribution Family Configs** (10-19, 20-29, 30-39):
- `10-fedora.conf` - Fedora-specific settings (all releases)
- `20-rhel.conf` - RHEL-specific settings (all releases)
- `30-centos.conf` - CentOS Stream-specific settings (all releases)

**Release-Specific Configs** (11-13, 21-22, 31-32):
- `11-fedora-42.conf` - Fedora 42 specific
- `12-fedora-43.conf` - Fedora 43 specific
- `13-fedora-rawhide.conf` - Fedora Rawhide specific
- `21-rhel-9.conf` - RHEL 9 specific
- `22-rhel-10.conf` - RHEL 10 specific
- `31-centos-9.conf` - CentOS Stream 9 specific
- `32-centos-10.conf` - CentOS Stream 10 specific

## How It Works

mkosi v26 automatically loads configuration in this order:

1. `mkosi.conf` - Base configuration
2. `mkosi.conf.d/*.conf` - Drop-ins (alphabetically sorted)
3. Settings that match are applied

Each drop-in uses `[Match]` sections to conditionally apply settings:

```ini
[Match]
Distribution=fedora
Release=42

[Distribution]
Release=42

[Output]
OutputDirectory=mkosi.output/f42

[Content]
Hostname=fedora-level0-dev
```

## Building

The build script automatically passes distribution and release:

```bash
# Build Fedora 42
./scripts/build-level.sh 0 --os f42

# Translates to:
mkosi -C configs/level-0-development -d fedora -r 42 build
```

## Output Directory Isolation

Each release has its own output subdirectory to prevent file conflicts:

```
mkosi.output/
├── f42/           # Fedora 42 outputs
├── f43/           # Fedora 43 outputs
├── rawhide/       # Fedora Rawhide outputs
├── rhel9/         # RHEL 9 outputs
├── rhel10/        # RHEL 10 outputs
├── centos9/       # CentOS Stream 9 outputs
└── centos10/      # CentOS Stream 10 outputs
```

**Benefits of isolated outputs:**
- ✅ Zero file conflicts between OS builds
- ✅ Keep multiple OS builds simultaneously
- ✅ Easy cleanup: `rm -rf mkosi.output/f43`
- ✅ Parallel builds possible (future enhancement)

## Adding New OS Variants

To add a new OS (e.g., Rocky Linux 9):

1. Create family drop-in if needed: `40-rocky.conf`
2. Create release drop-in: `41-rocky-9.conf` with `OutputDirectory=mkosi.output/rocky9`
3. Update `scripts/build-level.sh` OS case statement

Each drop-in is typically 4-8 lines, versus 141 lines for a full config.

## Benefits

- **DRY Principle**: Shared config in one place (packages, security settings)
- **Easy Maintenance**: Change once instead of 7 times
- **Scalability**: Add new OS with 4-8 lines instead of 141 lines
- **Consistency**: Impossible for configs to diverge
- **Output Isolation**: Each release builds to separate directory
