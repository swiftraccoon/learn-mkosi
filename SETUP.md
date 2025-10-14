# Setup Instructions

## mkosi Version Requirements

This repository requires **mkosi v26 or newer** for all security features (Secure Boot, dm-verity, etc.).

### Current Status

Fedora Rawhide currently ships mkosi v25.3, which lacks some features used in these configurations.

## Installation Options

### Option 1: Build mkosi from Source (Recommended)

Clone and build mkosi v26 from the official repository:

```bash
# Clone mkosi
cd ~
git clone https://github.com/systemd/mkosi.git
cd mkosi

# Check out latest version
git checkout main

# Create symlink in ~/.local/bin
mkdir -p ~/.local/bin
ln -sf "$(pwd)/bin/mkosi" ~/.local/bin/mkosi

# Verify
~/.local/bin/mkosi --version
# Should show: mkosi 26~devel
```

### Option 2: Install System mkosi (If v26+ Available)

```bash
# Check available version
dnf info mkosi

# Install only if v26+
sudo dnf install mkosi

# Verify version
mkosi --version  # Must be 26 or higher
```

## Add mkosi to PATH

Add `~/.local/bin` to your PATH so mkosi v26 is used by default:

```bash
# Add to ~/.bashrc or ~/.bash_profile
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc

# Verify it's now the default
which mkosi
# Should show: $HOME/.local/bin/mkosi

mkosi --version
# Should show: mkosi 26~devel (not 25.3)
```

## Building Your First Image

Once mkosi v26 is set up:

```bash
# Build Level 0 (Development)
./scripts/build-level.sh 0

# Build Level 1 (Production Baseline)
./scripts/build-level.sh 1

# Or build directly with mkosi
mkosi -C configs/level-0-development/f42 -f build
mkosi -C configs/level-1-minimal/f42 -f build
```

## Troubleshooting

### "Invalid boolean literal: 'unsigned'" Error

This means mkosi v25.3 is still being used. Solutions:

1. **Check PATH**:
   ```bash
   which mkosi
   # Should be: $HOME/.local/bin/mkosi (not /usr/bin/mkosi)
   ```

2. **Fix PATH**:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **Use absolute path**:
   ```bash
   ~/.local/bin/mkosi -C configs/level-1-minimal/f42 build
   ```

### Still Using Wrong Version

If `which mkosi` still shows `/usr/bin/mkosi`:

```bash
# Check PATH order
echo $PATH

# Prepend ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Verify
which mkosi
mkosi --version
```

### mkosi Not Found

If mkosi isn't in `~/.local/bin`:

```bash
# Clone mkosi source
cd ~
git clone https://github.com/systemd/mkosi.git
cd mkosi

# Create symlink
mkdir -p ~/.local/bin
ln -sf "$(pwd)/bin/mkosi" ~/.local/bin/mkosi

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

## Option: Downgrade Configs for mkosi v25 (Not Recommended)

If you must use mkosi v25.3, you can downgrade the configs (loses security features):

1. Edit each `mkosi.conf` file
2. Change `MinimumVersion=26` to `MinimumVersion=25`
3. Remove these lines:
   - `UnifiedKernelImages=unsigned`
   - `SecureBoot=yes`
   - `SecureBootAutoEnroll=yes`
4. Change `Verity=hash` to `Verity=data` (Level 2+)

**Note**: This significantly reduces security features. Use mkosi v26 instead.

## Verification

After setup, verify everything works:

```bash
# Check version
mkosi --version
# Must show: mkosi 26~devel or mkosi 26

# Test build (dry run)
mkosi -C configs/level-1-minimal/f42 summary

# Full build
mkosi -C configs/level-1-minimal/f42 -f build
```

## Next Steps

Once mkosi v26 is set up, proceed with [QUICKSTART.md](QUICKSTART.md).
