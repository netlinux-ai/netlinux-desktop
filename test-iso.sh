#!/bin/bash
# test-iso.sh — QEMU boot test for NetLinux Desktop ISO
# Boots the ISO with KVM, waits for SSH, runs a basic check.
# Usage: ./test-iso.sh <path-to-iso>
# Exit 0 = pass, Exit 1 = fail
set -euo pipefail

ISO="${1:?Usage: $0 <path-to-iso>}"
QEMU_PID=""
SSH_PORT=2222
TIMEOUT=180
POLL_INTERVAL=5
LIVE_USER="user"
LIVE_PASS="live"

SSH_BASE_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -o LogLevel=ERROR"

cleanup() {
    if [[ -n "$QEMU_PID" ]] && kill -0 "$QEMU_PID" 2>/dev/null; then
        echo "Killing QEMU (PID $QEMU_PID)..."
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    rm -f /tmp/netlinux-test-qemu.pid
}
trap cleanup EXIT

if [[ ! -f "$ISO" ]]; then
    echo "ERROR: ISO not found: $ISO"
    exit 1
fi

# Ensure SSH port is free
if ss -tln | grep -q ":${SSH_PORT} "; then
    echo "ERROR: Port $SSH_PORT already in use"
    exit 1
fi

echo "=== Boot test: $ISO ==="
echo "Starting QEMU with KVM, ${SSH_PORT}->22 port forward..."

qemu-system-x86_64 \
    -cdrom "$ISO" \
    -m 4096 \
    -enable-kvm \
    -cpu host \
    -smp 2 \
    -net nic \
    -net user,hostfwd=tcp::${SSH_PORT}-:22 \
    -display none \
    -daemonize \
    -pidfile /tmp/netlinux-test-qemu.pid

QEMU_PID=$(cat /tmp/netlinux-test-qemu.pid)
echo "QEMU started (PID $QEMU_PID)"

echo "Waiting up to ${TIMEOUT}s for SSH on localhost:${SSH_PORT}..."
ELAPSED=0
while [[ $ELAPSED -lt $TIMEOUT ]]; do
    if sshpass -p "$LIVE_PASS" ssh $SSH_BASE_OPTS \
           -p "$SSH_PORT" \
           "${LIVE_USER}@localhost" "echo SSH_OK" 2>/dev/null | grep -q SSH_OK; then
        echo "SSH connected after ${ELAPSED}s"

        echo "Running system check..."
        UNAME=$(sshpass -p "$LIVE_PASS" ssh $SSH_BASE_OPTS \
                    -p "$SSH_PORT" \
                    "${LIVE_USER}@localhost" "uname -a" 2>/dev/null)

        echo "Guest kernel: $UNAME"
        echo "=== BOOT TEST PASSED ==="
        exit 0
    fi

    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
    echo "  ${ELAPSED}s elapsed..."
done

echo "=== BOOT TEST FAILED — SSH timeout after ${TIMEOUT}s ==="
exit 1
