# ==============================================================
#  Ubuntu Desktop Profile – Packer build variables
#  This file defines ISO source and VM identity for Ubuntu.
#
#  KNOWN BROKEN ON ESXi (as of June 2026):
#  Ubuntu Desktop autoinstall reproducibly crashes on ESXi during
#  the curtin partitioning step with:
#     /dev/sda1: Sector 2048 already used.
#     Failed to add #1 partition: Numerical result out of range
#  This is a bug in the ubuntu-desktop-bootstrap snap (>= v494,
#  shipped with Ubuntu 24.04 LTS Desktop). It triggers regardless
#  of BIOS/UEFI firmware, disk controller (lsilogic-sas or pvscsi),
#  or memory configuration. The Ubuntu Server edition installs
#  fine on the same ESXi host with the same user-data, and the
#  same Desktop build works on Proxmox (different hardware
#  emulation). Needs an upstream fix from Canonical — retry this
#  profile once a newer snap ships.
#
#  Note: the iso_file below points to Ubuntu 24.04 LTS because
#  Ubuntu 26.04 has its own overlay-FS kernel bug on ESXi (see
#  the header of ubuntu_24_04_server.pkrvars.hcl).
# ==============================================================

# --------------------------------------------------------------
#  ISO ALREADY UPLOADED TO ESXi DATASTORE
#  Use this if you have manually uploaded the Ubuntu ISO to
#  your ESXi host's datastore under the "iso" folder.
# --------------------------------------------------------------
iso_datastore    = "datastore1" # Datastore name where the ISO is located
iso_file         = "iso/ubuntu-24.04-desktop-amd64.iso" # Path and filename of the ISO inside the pool
