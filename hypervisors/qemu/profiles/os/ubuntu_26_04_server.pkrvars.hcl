# ==============================================================
#  Ubuntu 26.04 Server profile — QEMU/KVM builder
# ==============================================================
#
# Supply the ISO as a local file (recommended for offline/air-gapped
# builds — download it once, then reference the local copy) or as a
# remote URL (Packer will download it to its cache on first build).
# ==============================================================

iso_url      = "file:///var/cache/isos/ubuntu-26.04-live-server-amd64.iso"
iso_checksum = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
# ^ Replace with the real SHA-256. One-liner on Linux:
#     sha256sum /var/cache/isos/ubuntu-26.04-live-server-amd64.iso
#
# You can also fetch directly from Canonical:
# iso_url      = "https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso"
# iso_checksum = "file:https://releases.ubuntu.com/26.04/SHA256SUMS"
