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
mkosi -C configs/level-0-development -d fedora -r 42 -f build
```

Build time: ~65 seconds

### Building RHEL Images

RHEL builds require subscription-manager registration:

```bash
# Install subscription-manager
sudo dnf install subscription-manager

# Register with Red Hat (free developer subscription available)
sudo subscription-manager register --username USERNAME

# Copy subscription certificates to mkosi sandbox
sudo mkdir -p configs/level-0-development/mkosi.sandbox/etc/rhsm/ca
sudo mkdir -p configs/level-0-development/mkosi.sandbox/etc/pki/entitlement
sudo cp /etc/rhsm/ca/redhat-uep.pem configs/level-0-development/mkosi.sandbox/etc/rhsm/ca/
sudo cp /etc/pki/entitlement/*.pem configs/level-0-development/mkosi.sandbox/etc/pki/entitlement/
sudo chown -R $USER:$USER configs/level-0-development/mkosi.sandbox

# Now build RHEL
./scripts/build-level.sh 0 --os rhel9
```

Get a free RHEL developer subscription at https://developers.redhat.com

## 3. Boot and Login

```bash
# Boot with QEMU (Fedora 42)
mkosi -C configs/level-0-development -d fedora -r 42 qemu

# At login prompt: Just press Enter (no password)
```

You're now running a minimal Fedora 42 system!

## Next Steps

- **For production**: Build Level 1 with `./scripts/build-level.sh 1`
- **Try other OS**: Use `--os f43`, `--os rawhide`, `--os rhel9`, etc.
- **Learn more**: Read [README.md](README.md) for full documentation
- **Customize**: Edit `configs/level-0-development/mkosi.conf` to add packages
