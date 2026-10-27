# ==============================================================
#  Debian 13 profile — QEMU/KVM builder
# ==============================================================
#
# Supply the ISO as a local file (recommended for offline/air-gapped
# builds — download it once, then reference the local copy) or as a
# remote URL (Packer will download it to its cache on first build).
#
# For a local file use `file:///absolute/path/...` (3 slashes).
# ==============================================================

iso_url      = "file:///var/cache/isos/debian-13.5.0-amd64-DVD-1.iso"
iso_checksum = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
# ^ Replace with the real SHA-256. One-liner on Linux:
#     sha256sum /var/cache/isos/debian-13.5.0-amd64-DVD-1.iso
#
# You can also fetch directly from Debian:
# iso_url      = "https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso"
# iso_checksum = "file:https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/SHA256SUMS"
