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
for script in postinst postrm preinst prerm; do
    [ -f "DEBIAN/${script}" ] && cp "DEBIAN/${script}" "${BUILD_DIR}/DEBIAN/" && chmod 755 "${BUILD_DIR}/DEBIAN/${script}"
done

# Build the .deb
dpkg-deb --build "${BUILD_DIR}" "${SCRIPT_DIR}/${PKG_NAME}.deb"

# Repack from zstd to xz for reprepro compatibility
REPACK_DIR=$(mktemp -d)
cd "$REPACK_DIR"
ar x "${SCRIPT_DIR}/${PKG_NAME}.deb"
for f in *.zst; do
    [ -f "$f" ] || continue
    zstd -d "$f"
    xz "${f%.zst}"
    rm "$f"
done
rm -f "${SCRIPT_DIR}/${PKG_NAME}.deb"
ar rcs "${SCRIPT_DIR}/${PKG_NAME}.deb" debian-binary control.tar.xz data.tar.xz
cd "$SCRIPT_DIR"

# Cleanup
rm -rf "${BUILD_DIR}" "${REPACK_DIR}"

echo "Built: ${SCRIPT_DIR}/${PKG_NAME}.deb"
echo ""
echo "Verify with:"
echo "  dpkg-deb --info ${PKG_NAME}.deb"
echo "  dpkg-deb --contents ${PKG_NAME}.deb"
