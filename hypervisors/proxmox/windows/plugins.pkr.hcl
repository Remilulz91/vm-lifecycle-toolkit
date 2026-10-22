# --- Packer Global Configuration & Plugins ---
packer {
  required_version = ">= 1.11.0"
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.1.0"
    }
  }
}
