#!/usr/bin/env bash
# ============================================================
# prepare-offline-bundle.sh
# ------------------------------------------------------------
# Run this script on an ONLINE machine (with internet + pip +
# ansible-galaxy available) to produce a self-contained archive
# that you can then transfer to the OFFLINE / air-gapped machine
# where you want to run the Ansible playbooks.
#
# The archive contains:
#   - All Ansible collections declared in requirements.yml
#     (downloaded as .tar.gz files)
#   - All Python wheels needed by requirements.txt
#     (proxmoxer, requests, and their transitive deps)
#   - A copy of requirements.yml and requirements.txt
#
# Usage:
#   cd ansible/
#   bash scripts/prepare-offline-bundle.sh
#
# Output:
#   ansible/offline-bundle/offline-bundle-YYYYMMDD.tar.gz
#
# Then transfer that single .tar.gz file to the offline machine
# (USB stick, internal share, scp through a bastion, etc.)
# and run scripts/install-offline-bundle.sh over there.
# ============================================================

set -euo pipefail

# ---------- Prerequisites ----------
command -v ansible-galaxy >/dev/null 2>&1 || {
  echo "ERROR: ansible-galaxy not found. Install ansible-core first (apt, pip, …)."
  exit 1
}
command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1 || {
  echo "ERROR: pip (or pip3) not found. Install Python 3 + pip first."
  exit 1
}
PIP_BIN="$(command -v pip3 || command -v pip)"

# ---------- Locate files relative to this script ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REQ_YML="$ANSIBLE_DIR/requirements.yml"
REQ_TXT="$ANSIBLE_DIR/requirements.txt"

[[ -f "$REQ_YML" ]] || { echo "ERROR: $REQ_YML not found."; exit 1; }
[[ -f "$REQ_TXT" ]] || { echo "ERROR: $REQ_TXT not found."; exit 1; }

# ---------- Workspace ----------
BUNDLE_ROOT="$ANSIBLE_DIR/offline-bundle"
STAGING_DIR="$BUNDLE_ROOT/staging"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_NAME="offline-bundle-${STAMP}.tar.gz"
ARCHIVE_PATH="$BUNDLE_ROOT/$ARCHIVE_NAME"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/collections" "$STAGING_DIR/wheels"

echo "============================================================"
echo "Preparing offline bundle for VM Lifecycle Toolkit (Ansible)"
echo "============================================================"
echo "Staging dir : $STAGING_DIR"
echo "Output      : $ARCHIVE_PATH"
echo

# ---------- 1. Ansible collections (as .tar.gz) ----------
echo "[1/3] Downloading Ansible collections (ansible-galaxy collection download)..."
ansible-galaxy collection download \
  -r "$REQ_YML" \
  -p "$STAGING_DIR/collections"
echo "  → done. Collections saved under: $STAGING_DIR/collections/"
echo

# ---------- 2. Python wheels ----------
echo "[2/3] Downloading Python wheels (pip download)..."
"$PIP_BIN" download \
  -r "$REQ_TXT" \
  -d "$STAGING_DIR/wheels"
echo "  → done. Wheels saved under: $STAGING_DIR/wheels/"
echo

# ---------- 3. Copy requirements files for reference ----------
echo "[3/3] Copying requirements files into the bundle..."
cp "$REQ_YML" "$STAGING_DIR/requirements.yml"
cp "$REQ_TXT" "$STAGING_DIR/requirements.txt"

# A tiny README inside the bundle
cat > "$STAGING_DIR/BUNDLE-README.txt" <<EOF
VM Lifecycle Toolkit — offline bundle
Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Host:      $(hostname 2>/dev/null || echo unknown)

Contents:
  collections/   Ansible collections (.tar.gz files)
  wheels/        Python wheels (.whl / .tar.gz)
  requirements.yml, requirements.txt  — the exact dependency lists
                                         used to build this bundle

How to install on the offline machine:
  1. Transfer the enclosing offline-bundle-*.tar.gz archive.
  2. Extract it next to the ansible/ directory on the offline host.
  3. Run:  bash ansible/scripts/install-offline-bundle.sh \\
             /path/to/extracted/bundle
EOF
echo "  → done."
echo

# ---------- Pack ----------
echo "Packing $ARCHIVE_NAME ..."
tar czf "$ARCHIVE_PATH" -C "$BUNDLE_ROOT" staging
rm -rf "$STAGING_DIR"

echo
echo "============================================================"
echo "✅ Offline bundle ready:"
echo "   $ARCHIVE_PATH"
echo "============================================================"
echo
echo "Next step: transfer this file to the offline machine, then run"
echo "           ansible/scripts/install-offline-bundle.sh over there."
