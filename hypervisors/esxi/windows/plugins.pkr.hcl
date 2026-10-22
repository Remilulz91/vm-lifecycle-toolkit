# --- Packer Global Configuration & Plugins ---
packer {
  required_version = ">= 1.11.0"
  required_plugins {
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = ">= 1.0.0"
    }
  }
}
