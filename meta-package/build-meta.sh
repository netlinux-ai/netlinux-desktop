#!/bin/bash
# build-meta.sh — Build the netlinux-desktop meta-package .deb
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Read version from control file
VERSION=$(grep '^Version:' DEBIAN/control | awk '{print $2}')
PKG_NAME="netlinux-desktop_${VERSION}_all"

echo "=== Building ${PKG_NAME}.deb ==="

# Create clean build directory
BUILD_DIR=$(mktemp -d)
mkdir -p "${BUILD_DIR}/DEBIAN"
cp DEBIAN/control "${BUILD_DIR}/DEBIAN/"

# Build the .deb
dpkg-deb --build "${BUILD_DIR}" "${SCRIPT_DIR}/${PKG_NAME}.deb"

# Cleanup
rm -rf "${BUILD_DIR}"

echo "Built: ${SCRIPT_DIR}/${PKG_NAME}.deb"
echo ""
echo "Verify with:"
echo "  dpkg-deb --info ${PKG_NAME}.deb"
echo "  dpkg-deb --contents ${PKG_NAME}.deb"
