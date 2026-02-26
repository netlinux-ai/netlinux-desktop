#!/bin/bash
# nightly-build.sh — NetLinux Desktop nightly build pipeline
# Builds, tests, and publishes the ISO if there are new commits.
# Must run as root (required by live-build).
set -euo pipefail

REPO_DIR="/home/graham/netlinux-desktop"
LAST_COMMIT_FILE="${REPO_DIR}/.nightly-last-commit"
LOG_FILE="${REPO_DIR}/nightly.log"
PACKAGES_HOST="root@packages.netlinux.co.uk"
PACKAGES_DIR="/Sites/netlinux/packages"
ISO_NAME="netlinux-desktop-nightly.iso"
SSH_KEY="/home/graham/.ssh/id_rsa"
SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"

# Use graham's SSH key for all SSH/git operations (script runs as root)
export GIT_SSH_COMMAND="ssh ${SSH_OPTS}"

# Logging: all output goes to both stdout and log file with timestamps
exec > >(while IFS= read -r line; do echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"; done | tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo "NetLinux Desktop nightly build starting"
echo "========================================="

cd "$REPO_DIR"

# --- Step 1: Check for new commits ---
echo ">>> Fetching latest from origin..."
sudo -u graham git fetch origin

REMOTE_COMMIT=$(sudo -u graham git rev-parse origin/main)
LAST_BUILT=""
if [[ -f "$LAST_COMMIT_FILE" ]]; then
    LAST_BUILT=$(cat "$LAST_COMMIT_FILE")
fi

echo "Remote HEAD: $REMOTE_COMMIT"
echo "Last built:  ${LAST_BUILT:-never}"


# --- Step 2: Pull latest ---
echo ">>> Pulling latest changes..."
sudo -u graham git pull origin main

# --- Step 3: Build ---
echo ">>> Starting ISO build..."
BUILD_START=$(date +%s)

# build.sh handles deps, GPG key, branding, lb clean/config/build
# Use 'yes' to auto-answer low disk space prompt; ignore SIGPIPE from yes
set +o pipefail
yes "" 2>/dev/null | ./build.sh
set -o pipefail

# Verify build actually produced an ISO
ISO_FILE=$(ls -1 "${REPO_DIR}"/netlinux-desktop-*.iso 2>/dev/null | head -1)
if [[ -z "$ISO_FILE" ]]; then
    echo "ERROR: No ISO file found after build"
    exit 1
fi

BUILD_END=$(date +%s)
BUILD_DURATION=$(( (BUILD_END - BUILD_START) / 60 ))
echo "Build completed in ${BUILD_DURATION} minutes"
echo "Built ISO: $ISO_FILE"

# --- Step 4: Test ---
echo ">>> Running boot test..."
if ! "${REPO_DIR}/test-iso.sh" "$ISO_FILE"; then
    echo "ERROR: Boot test FAILED — not publishing"
    exit 1
fi

# --- Step 5: Publish ---
echo ">>> Uploading ISO to packages server..."
scp ${SSH_OPTS} "$ISO_FILE" "${PACKAGES_HOST}:${PACKAGES_DIR}/${ISO_NAME}"

BUILD_DATE=$(date '+%d %B %Y')
echo ">>> Updating netlinux.html..."
ssh ${SSH_OPTS} "$PACKAGES_HOST" "${PACKAGES_DIR}/webhook/update-nightly-html.sh" \
    "'$REMOTE_COMMIT'" "'$BUILD_DATE'"

echo "Published: https://packages.netlinux.co.uk/${ISO_NAME}"

# --- Step 6: Record success ---
echo "$REMOTE_COMMIT" > "$LAST_COMMIT_FILE"
echo "Recorded commit $REMOTE_COMMIT as last built"

# --- Step 7: Cleanup ---
echo ">>> Cleaning up local ISO..."
rm -f "${REPO_DIR}"/netlinux-desktop-*.iso
echo "Local ISO removed (chroot/cache preserved for faster rebuilds)"

echo "========================================="
echo "Nightly build complete"
echo "========================================="
