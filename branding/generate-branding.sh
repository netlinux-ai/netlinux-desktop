#!/bin/bash
# Generate NetLinux branding assets from source logo
# Requires: imagemagick
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source logo — try local copy first, then /Data/NetLinux/
SOURCE_LOGO="$SCRIPT_DIR/NetLinux.png"
if [[ ! -f "$SOURCE_LOGO" ]]; then
    SOURCE_LOGO="/Data/NetLinux/NetLinux.png"
fi

if [[ ! -f "$SOURCE_LOGO" ]]; then
    echo "ERROR: Source logo not found. Place NetLinux.png in branding/ directory."
    exit 1
fi

# Install ImageMagick if needed
if ! command -v convert &>/dev/null; then
    echo "Installing imagemagick..."
    apt-get install -y imagemagick
fi

BACKGROUNDS_DIR="$PROJECT_DIR/config/includes.chroot/usr/share/backgrounds"
PIXMAPS_DIR="$PROJECT_DIR/config/includes.chroot/usr/share/pixmaps"
PLYMOUTH_DIR="$PROJECT_DIR/config/includes.chroot/usr/share/plymouth/themes/netlinux"
CALAMARES_DIR="$PROJECT_DIR/config/includes.chroot/etc/calamares/branding/netlinux"

mkdir -p "$BACKGROUNDS_DIR" "$PIXMAPS_DIR" "$PLYMOUTH_DIR" "$CALAMARES_DIR"

echo ">>> Generating desktop wallpaper (1920x1080)..."
# Dark background with subtle radial gradient and centred logo
convert -size 1920x1080 \
    radial-gradient:"#1a1a1a"-"#0a0a0a" \
    \( "$SOURCE_LOGO" -resize 500x \) \
    -gravity center -composite \
    \( -size 1920x1080 xc:none \
       -fill "rgba(0,232,123,0.03)" \
       -draw "circle 960,540 960,100" \
    \) -composite \
    "$BACKGROUNDS_DIR/netlinux-wallpaper.png"
echo "    -> $BACKGROUNDS_DIR/netlinux-wallpaper.png"

echo ">>> Generating logo for pixmaps (128x128)..."
convert "$SOURCE_LOGO" -resize 128x128 -background none -gravity center -extent 128x128 \
    "$PIXMAPS_DIR/netlinux-logo.png"
echo "    -> $PIXMAPS_DIR/netlinux-logo.png"

echo ">>> Generating Plymouth logo..."
convert "$SOURCE_LOGO" -resize 300x \
    "$PLYMOUTH_DIR/netlinux-logo.png"
echo "    -> $PLYMOUTH_DIR/netlinux-logo.png"

echo ">>> Generating Calamares branding images..."
# Sidebar logo for Calamares
convert "$SOURCE_LOGO" -resize 64x64 -background none -gravity center -extent 64x64 \
    "$CALAMARES_DIR/netlinux-logo.png"
echo "    -> $CALAMARES_DIR/netlinux-logo.png"

# Welcome image for Calamares
convert -size 800x300 \
    radial-gradient:"#1a1a1a"-"#0a0a0a" \
    \( "$SOURCE_LOGO" -resize 400x \) \
    -gravity center -composite \
    "$CALAMARES_DIR/netlinux-welcome.png"
echo "    -> $CALAMARES_DIR/netlinux-welcome.png"

# Simple QML slideshow for Calamares
cat > "$CALAMARES_DIR/show.qml" << 'QMLEOF'
import QtQuick 2.0

Item {
    id: root
    width: 800
    height: 440

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"

        Text {
            anchors.centerIn: parent
            text: "Installing NetLinux Desktop..."
            color: "#00e87b"
            font.pixelSize: 24
            font.family: "DejaVu Sans"
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Linux Engineering. Applied AI. Energy Decarbonisation."
            color: "#666666"
            font.pixelSize: 14
            font.family: "DejaVu Sans"
        }
    }
}
QMLEOF
echo "    -> $CALAMARES_DIR/show.qml"

echo ">>> Branding generation complete."
