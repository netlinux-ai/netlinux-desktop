#!/bin/bash
# NetLinux Desktop ISO Build Script
# Builds a Debian bookworm-based live ISO with Xfce, Calamares, and NetLinux packages
set -e

# Must run as root (live-build requires chroot/mount)
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Re-executing with sudo..."
    exec sudo "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== NetLinux Desktop ISO Builder ==="
echo ""

# Check available disk space (need at least 15GB)
AVAIL_KB=$(df --output=avail "$SCRIPT_DIR" | tail -1)
AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
if [[ $AVAIL_GB -lt 15 ]]; then
    echo "WARNING: Only ${AVAIL_GB}GB available. At least 15GB recommended."
    echo "Continue anyway? (y/N)"
    read -r answer
    [[ "$answer" =~ ^[Yy] ]] || exit 1
fi

# Install live-build if needed
if ! command -v lb &>/dev/null; then
    echo ">>> Installing live-build..."
    apt-get update
    apt-get install -y live-build
fi

# Install debootstrap if needed
if ! command -v debootstrap &>/dev/null; then
    echo ">>> Installing debootstrap..."
    apt-get install -y debootstrap
fi

# Download NetLinux repo GPG key if not present
if [[ ! -f config/archives/netlinux.key.chroot ]]; then
    echo ">>> Downloading NetLinux repository GPG key..."
    wget -q -O config/archives/netlinux.key.chroot \
        https://packages.netlinux.co.uk/debian/repo-key.gpg
    cp config/archives/netlinux.key.chroot config/archives/netlinux.key.binary
fi

# Generate branding assets if needed
if [[ ! -f config/includes.chroot/usr/share/backgrounds/netlinux-wallpaper.png ]]; then
    echo ">>> Generating branding assets..."
    if [[ -x branding/generate-branding.sh ]]; then
        bash branding/generate-branding.sh
    else
        echo "WARNING: branding/generate-branding.sh not found or not executable."
        echo "         Wallpaper and logo will not be generated."
    fi
fi

# Make auto scripts executable
chmod +x auto/*

# Clean previous build (if any)
echo ">>> Cleaning previous build artifacts..."
lb clean 2>/dev/null || true

# Configure
echo ">>> Running lb config..."
lb config

# Build
echo ">>> Building ISO (this will take 20-40 minutes)..."
lb build 2>&1 | tee build.log

# Report result
ISO_FILE=$(ls -1 netlinux-desktop-*.iso 2>/dev/null | head -1)
if [[ -n "$ISO_FILE" ]]; then
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    echo ""
    echo "=== Build complete! ==="
    echo "ISO: $ISO_FILE ($ISO_SIZE)"
    echo ""
    echo "Test with QEMU:"
    echo "  qemu-system-x86_64 -cdrom $ISO_FILE -m 4096 -enable-kvm"
    echo ""
    echo "Write to USB:"
    echo "  dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress oflag=sync"
else
    echo ""
    echo "=== Build FAILED ==="
    echo "Check build.log for details."
    exit 1
fi
