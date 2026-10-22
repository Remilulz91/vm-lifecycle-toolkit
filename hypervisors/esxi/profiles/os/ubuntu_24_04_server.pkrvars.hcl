# ==============================================================
#  Ubuntu Server Profile – Packer build variables
#  This file defines ISO source and VM identity for Ubuntu.
#
#  We target Ubuntu 24.04 LTS (Noble) here because Ubuntu 26.04
#  ships a kernel with a reproducible overlay-FS bug that crashes
#  Subiquity's curtin extract phase when installing on ESXi
#  (the same 26.04 build works on Proxmox). 24.04 LTS uses an
#  older kernel without this bug and works reliably on ESXi.
#  When Ubuntu 26.04 ships a kernel fix in a point release, a new
#  profile (ubuntu_26_04_server.pkrvars.hcl) can be added without
#  disrupting this one.
# ==============================================================

# --------------------------------------------------------------
#  ISO ALREADY UPLOADED TO ESXi DATASTORE
#  Use this if you have manually uploaded the Ubuntu ISO to
#  your ESXi host's datastore under the "iso" folder.
# --------------------------------------------------------------
iso_datastore    = "datastore1" # Datastore name where the ISO is located
iso_file         = "iso/ubuntu-24.04-live-server-amd64.iso" # Path and filename of the ISO inside the pool
