# NetLinux Desktop

Debian bookworm-based live ISO with Xfce desktop, Calamares installer, and all NetLinux packages pre-installed.

## What's included

- **Kernel:** NetLinux 6.19 custom kernel
- **Desktop:** Xfce 4 with Openbox as alternative WM
- **Browser:** Chromium + Firefox ESR
- **Creative:** GIMP, Blender, FreeCAD (CuraEngine + fstl)
- **Remote:** TightVNC, x11vnc
- **AI:** Claude Code
- **System:** SSH server, bridge-utils, DKMS, build-essential
- **Installer:** Calamares graphical installer

## Building

### Prerequisites

- Debian or Ubuntu host (tested on Ubuntu 24.04)
- Root access (live-build requires chroot/mount)
- ~20GB free disk space
- Internet access (to download packages)

### Quick build

```bash
git clone https://github.com/netlinux-ai/netlinux-desktop.git
cd netlinux-desktop
sudo ./build.sh
```

The ISO will be output as `netlinux-desktop-amd64.hybrid.iso`.

### Manual build

```bash
# Install live-build
sudo apt-get install -y live-build debootstrap

# Download repo GPG key
wget -O config/archives/netlinux.key.chroot https://packages.netlinux.co.uk/debian/repo-key.gpg
cp config/archives/netlinux.key.chroot config/archives/netlinux.key.binary

# Generate branding (requires imagemagick)
sudo bash branding/generate-branding.sh

# Build
chmod +x auto/*
sudo lb config
sudo lb build
```

## Testing

### QEMU

```bash
qemu-system-x86_64 -cdrom netlinux-desktop-amd64.hybrid.iso -m 4096 -enable-kvm
```

### USB drive

```bash
sudo dd if=netlinux-desktop-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Boot options

| Menu entry | Description |
|------------|-------------|
| NetLinux Desktop (Live) | Boot into live desktop session |
| NetLinux Desktop (Live, safe graphics) | Boot with `nomodeset` for GPU issues |
| Install NetLinux Desktop | Boot live then auto-launch Calamares installer |

## Branding

Corporate colours: terminal green `#00e87b` on dark background `#0a0a0a`.

To regenerate branding assets from the source logo:

```bash
sudo bash branding/generate-branding.sh
```

## Project structure

```
auto/           - live-build auto scripts (config, build, clean)
config/
  archives/     - APT sources and GPG keys for NetLinux repo
  package-lists/ - Package lists (desktop, netlinux, system, installer)
  includes.chroot/ - Files included in the live filesystem
  hooks/normal/ - Chroot hooks for customisation
  bootloaders/  - GRUB/syslinux configuration
branding/       - Source logo and branding generator
build.sh        - Top-level build script
```

## NetLinux

Linux Engineering. Applied AI. Energy Decarbonisation.

https://netlinux.co.uk
