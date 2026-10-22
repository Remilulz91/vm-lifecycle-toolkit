# ==============================================================
#  Ubuntu 26.04 Desktop Profile – Packer build variables
#  This file defines ISO source and VM identity for Ubuntu.
# ==============================================================

# --------------------------------------------------------------
#  ISO ALREADY UPLOADED TO PROXMOX
#  Use this if you have manually uploaded the Ubuntu ISO to
#  your Proxmox node under "local → ISO Images".
# --------------------------------------------------------------
iso_storage_pool = "local" # Storage pool name where the ISO is located
iso_file         = "iso/ubuntu-26.04-desktop-amd64.iso" # Path and filename of the ISO inside the pool
