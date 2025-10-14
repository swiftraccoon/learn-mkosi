# Quick Start Guide

Build and boot your first minimal Linux image in under 2 minutes.

## 1. Install mkosi v26

```bash
# Clone mkosi
git clone https://github.com/systemd/mkosi.git ~/mkosi
cd ~/mkosi

# Create symlink
mkdir -p ~/.local/bin
ln -sf "$(pwd)/bin/mkosi" ~/.local/bin/mkosi

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
mkosi --version  # Should show: mkosi 26~devel
```

## 2. Build Level 0 (Development)

```bash
# Clone this repository (if you haven't already)
git clone https://github.com/swiftraccoon/learn-mkosi.git
cd learn-mkosi

# Build Fedora 42 development image
./scripts/build-level.sh 0

# Or build directly
mkosi -C configs/level-0-development/f42 -f build
```

Build time: ~65 seconds

## 3. Boot and Login

```bash
# Boot with QEMU
mkosi -C configs/level-0-development/f42 qemu

# At login prompt: Just press Enter (no password)
```

You're now running a minimal Fedora 42 system!

## Next Steps

- **For production**: Build Level 1 with `./scripts/build-level.sh 1`
- **Try other OS**: Use `--os f43`, `--os rawhide`, `--os rhel9`, etc.
- **Learn more**: Read [README.md](README.md) for full documentation
- **Customize**: Edit `configs/level-0-development/f42/mkosi.conf` to add packages
