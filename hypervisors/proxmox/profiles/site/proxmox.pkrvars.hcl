# --- Proxmox connection settings ---
proxmox_url          = "https://192.168.10.195:8006/api2/json" # URL of your Proxmox API endpoint (e.g., https://192.168.1.10:8006/api2/json)
proxmox_node         = "suli-prmx1-ve" # Name of the Proxmox node where the VM will be created
proxmox_token_id     = "packer@pam!ci" # API token ID in the format: <user>@<realm>!<token_name> (e.g., packer@pam!ci)
proxmox_token_secret = "7075cd3b-5522-496d-a3a4-b5c9fe14879c" # Secret key associated with the Proxmox API token

# --- Storage and network configuration ---
disk_storage_pool = "vm_storage" # Name of the Proxmox storage pool to use for the VM’s disk (e.g., local-lvm, local, or SSD)
bridge            = "vmbr0" # Name of the Proxmox network bridge the VM will attach to (e.g., vmbr0)
