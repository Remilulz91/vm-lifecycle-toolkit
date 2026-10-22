# ==============================================================
#  Debian 13 Profile – Packer build variables for Proxmox template
#  This file defines ISO source and VM identity for Debian 13.
# ==============================================================

# --------------------------------------------------------------
#  ISO ALREADY UPLOADED TO PROXMOX
#  Use this if you have manually uploaded the Debian ISO to
#  your Proxmox node under "local → ISO Images".
# --------------------------------------------------------------
iso_storage_pool = "local" # Storage pool name where the ISO is located
iso_file         = "iso/debian-13.5.0-amd64-DVD-1.iso" # Path and filename of the ISO inside the pool
