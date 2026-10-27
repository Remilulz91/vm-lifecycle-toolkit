#!/usr/bin/env bash
# ============================================================
# install-offline-bundle.sh
# ------------------------------------------------------------
# Run this script on the OFFLINE / air-gapped machine, AFTER
# you have transferred and extracted the offline-bundle-*.tar.gz
# produced by prepare-offline-bundle.sh.
#
# It will:
#   - Create (if needed) a Python venv under ansible/venv/
#   - Install the Python packages from local wheels (no PyPI)
#   - Install the Ansible collections from local tar.gz files
#     into ansible/collections/ (no Galaxy)
#
# Usage:
#   bash ansible/scripts/install-offline-bundle.sh \
#        /path/to/extracted/bundle
#
# Where /path/to/extracted/bundle is the directory that contains
# the two subfolders "collections/" and "wheels/" (i.e. the
# "staging" folder from the archive).
# ============================================================

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-extracted-bundle>"
  echo "The folder must contain 'collections/' and 'wheels/' subdirs."
  exit 1
fi

BUNDLE_DIR="$(cd "$1" && pwd)"
COLLECTIONS_SRC="$BUNDLE_DIR/collections"
WHEELS_SRC="$BUNDLE_DIR/wheels"
REQ_YML="$BUNDLE_DIR/requirements.yml"
REQ_TXT="$BUNDLE_DIR/requirements.txt"

[[ -d "$COLLECTIONS_SRC" ]] || { echo "ERROR: $COLLECTIONS_SRC missing."; exit 1; }
[[ -d "$WHEELS_SRC"     ]] || { echo "ERROR: $WHEELS_SRC missing.";     exit 1; }
[[ -f "$REQ_YML"        ]] || { echo "ERROR: $REQ_YML missing.";        exit 1; }
[[ -f "$REQ_TXT"        ]] || { echo "ERROR: $REQ_TXT missing.";        exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$ANSIBLE_DIR/venv"
COLLECTIONS_DEST="$ANSIBLE_DIR/collections"

echo "============================================================"
echo "Installing offline bundle on this host"
echo "============================================================"
echo "Bundle            : $BUNDLE_DIR"
echo "Ansible dir       : $ANSIBLE_DIR"
echo "Venv              : $VENV_DIR"
echo "Collections dest  : $COLLECTIONS_DEST"
echo

# ---------- 1. Python venv + wheels ----------
echo "[1/2] Setting up Python venv and installing wheels (no internet)..."
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

pip install --no-index --find-links "$WHEELS_SRC" --upgrade pip || true
pip install --no-index --find-links "$WHEELS_SRC" -r "$REQ_TXT"

echo "  → Python deps installed:"
pip list | grep -Ei '^(proxmoxer|requests)\b' || true
echo

# ---------- 2. Ansible collections ----------
echo "[2/2] Installing Ansible collections from local tarballs (no Galaxy)..."
mkdir -p "$COLLECTIONS_DEST"

# ansible-galaxy accepts a requirements.yml that points at local
# tar.gz files via the "source:" key. We generate it on the fly from
# whatever .tar.gz files are present in the bundle so this stays
# resilient to version changes.
LOCAL_REQ="$BUNDLE_DIR/requirements-local.yml"
{
  echo "---"
  echo "collections:"
  for tgz in "$COLLECTIONS_SRC"/*.tar.gz; do
    [[ -f "$tgz" ]] || continue
    echo "  - name: $tgz"
    echo "    type: file"
  done
} > "$LOCAL_REQ"

ansible-galaxy collection install \
  -r "$LOCAL_REQ" \
  -p "$COLLECTIONS_DEST" \
  --offline

echo "  → Collections installed under $COLLECTIONS_DEST/"
ansible-galaxy collection list -p "$COLLECTIONS_DEST" || true
echo

echo "============================================================"
echo "✅ Offline install complete."
echo "============================================================"
echo
echo "Next steps on this host:"
echo "  1. source $VENV_DIR/bin/activate"
echo "  2. export PROXMOX_API_HOST=... PROXMOX_NODE=... PROXMOX_API_TOKEN_SECRET=..."
echo "  3. cd $ANSIBLE_DIR"
echo "  4. ansible-playbook playbooks/clone-from-template.yml"
