# ==============================================================
#  Debian 13 Profile – Packer build variables for ESXi template
#  This file defines ISO source and VM identity for Debian 13.
# ==============================================================

# --------------------------------------------------------------
#  ISO ALREADY UPLOADED TO ESXi DATASTORE
#  Use this if you have manually uploaded the Debian ISO to
#  your ESXi host's datastore under the "iso" folder.
# --------------------------------------------------------------
iso_datastore    = "datastore1" # Datastore name where the ISO is located
iso_file         = "iso/debian-13.5.0-amd64-DVD-1.iso" # Path and filename of the ISO inside the pool
