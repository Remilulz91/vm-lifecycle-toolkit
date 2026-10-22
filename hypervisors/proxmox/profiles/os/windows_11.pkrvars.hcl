# ==============================================================
#  Windows 11 Profile – Packer build variables for Proxmox template
#  This file defines ISO source and VM identity for Windows 11.
# ==============================================================

# --------------------------------------------------------------
#  ISO ALREADY UPLOADED TO PROXMOX
#  Use this if you have manually uploaded the Windows ISO to
#  your Proxmox node under "local → ISO Images".
# --------------------------------------------------------------
iso_storage_pool = "local" # Storage pool name where the ISO is located
iso_file         = "iso/Win11_25H2_French_x64.iso" # Path and filename of the ISO inside the pool
virtio_iso_file  = "iso/virtio-win-0.1.285.iso" # Path and filename of the ISO inside the pool
