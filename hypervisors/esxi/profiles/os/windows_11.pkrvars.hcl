# ==============================================================
#  Windows 11 Profile – Packer build variables for ESXi template
#  This file defines ISO sources and VM identity for Windows 11.
# ==============================================================

# --------------------------------------------------------------
#  ISOs ALREADY UPLOADED TO ESXi DATASTORE
#  Both the Windows install ISO and the VMware Tools ISO must be
#  uploaded manually to your ESXi host's datastore under the
#  "iso" folder before running the build.
# --------------------------------------------------------------
iso_datastore         = "datastore1" # Datastore name where the ISOs are located
iso_file              = "iso/Win11_25H2_French_x64.iso" # Path and filename of the Windows install ISO
vmware_tools_iso_file = "iso/VMware-tools-windows.iso"  # Path and filename of the VMware Tools ISO (rename your upload to match)
