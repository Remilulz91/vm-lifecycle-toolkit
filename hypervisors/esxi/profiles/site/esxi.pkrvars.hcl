# --- vSphere/ESXi connection settings ---
vsphere_url      = "192.168.10.253" # ESXi host URL or IP (just the host — no /api path)
vsphere_host     = "localhost.localdomain" # Hostname of the ESXi as it appears in the vSphere inventory
vsphere_username = "root" # Username used to authenticate against the ESXi host (typically "root" for standalone ESXi)
# vsphere_password is intentionally NOT set here. Pass it at build time with:
#   -var "vsphere_password=..."

# --- Storage and network configuration ---
datastore = "datastore1" # VMFS datastore used for the VM disk
network   = "VM Network" # Portgroup the VM NIC will attach to
