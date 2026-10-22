# ==============================================================
#  Proxmox API & SSH connection variables
#  Used by Packer to authenticate to Proxmox and (optionally) SSH
#  into the Proxmox node for post-build tweaks.
# ==============================================================

# Proxmox API endpoint, including /api2/json
# Example: "https://pve01:8006/api2/json"
variable "proxmox_url" {
  type = string
}

# API token ID (format: user@realm!token)
# Example: "packer@pam!ci"
variable "proxmox_token_id" {
  type = string
}

# Secret for the API token. Marked sensitive so it won't leak in logs.
variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

# Target Proxmox node where the VM is created (as shown by `pvesh get /nodes`)
# Example: "pve01"
variable "proxmox_node" {
  type = string
}

# ==============================================================
#  Template identity (required)
# ==============================================================

# Required: Proxmox VMID for the template.
# Must be manually provided via -var or in a .pkrvars.hcl file.
variable "template_id" {
  type = number
  # Basic safety check to ensure we don't overwrite low-ID system VMs
  validation {
    condition     = var.template_id >= 1000
    error_message = "Template_id must be greater than or equal to 1000; choose a free VMID in your Proxmox cluster."
  }
}

# Required: Human-readable template name (also used as the OS hostname).
# Must be passed explicitly; no default value is provided.
variable "template_name" {
  type = string
  validation {
    # Must:
    #  - Contain only lowercase letters, digits, and hyphens
    #  - Not start or end with a hyphen
    #  - Be between 1 and 63 characters long
    #  - Contain no spaces
    condition     = can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.template_name))
    error_message = "Template_name must be a valid Windows hostname (1–15 chars, lowercase letters, digits, or hyphens, and must not start or end with a hyphen)."
  }
}

# ==============================================================
#  VM hardware resources
# ==============================================================

# vCPU count (applies to all templates)
variable "cpus" {
  type    = number
  default = 2
  validation {
    condition     = var.cpus >= 1
    error_message = "Cpus must be greater than or equal to 1."
  }
}

# RAM in MiB (Windows 11 officially requires 4GB, practical minimum is 2GB)
variable "memory" {
  type    = number
  default = 4096
  validation {
    condition     = var.memory >= 2048
    error_message = "Memory must be at least 2048 MiB for Windows."
  }
}

# System disk size in GB (Windows 11 officially requires 64GB, practical minimum is 40GB)
variable "disk_gb" {
  type    = number
  default = 64
  validation {
    condition     = var.disk_gb >= 40
    error_message = "Disk size must be at least 40 GB for Windows."
  }
}

# Number of CPU sockets (total vCPUs = sockets * cores)
variable "sockets" {
  type    = number
  default = 1
  validation {
    condition     = var.sockets >= 1
    error_message = "Sockets must be 1 or greater."
  }
}

# ==============================================================
#  Storage and networking
# ==============================================================

# Proxmox storage pool used for the VM disk (e.g., "local-lvm")
variable "disk_storage_pool" {
  type = string
}

# Proxmox bridge for the NIC (e.g., "vmbr0")
variable "bridge" {
  type = string
}

# ==============================================================
#  ISO source (generic)
#  Used by ISO-based installs (Windows).
# ==============================================================

# Proxmox storage pool that contains the installer ISO (e.g., "local").
variable "iso_storage_pool" {
  type = string
}

# Path to the installer ISO inside the storage pool (e.g., "iso/Win11_25H2_French_x64.iso").
variable "iso_file" {
  type = string
}

# Path to the VirtIO ISO inside the storage pool (specifically for Windows).
# Example: "iso/virtio-win-0.1.285.iso"
variable "virtio_iso_file" {
  type    = string
}

# ==============================================================
#  Accounts used inside the guest during/after installation
# ==============================================================

# --- Administrator Account (Root equivalent) ---
# Configurable admin username (defaults to "root").
variable "admin_username" {
  type    = string
  default = "root"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_][-a-zA-Z0-9_]*$", var.admin_username))
    error_message = "Admin_username must be a valid username (no spaces, standard characters only)."
  }
}

# Password for the admin account.
# ***Required***: the build will fail if not provided.
variable "admin_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.admin_password) > 0
    error_message = "Admin_password is required. Provide a non-empty password."
  }
}

# --- Standard User Account ---
# Configurable standard user (defaults to "buildmaster").
variable "user_username" {
  type    = string
  default = "buildmaster"
  validation {
    condition     = can(regex("^[a-z0-9_][-a-z0-9_]*$", var.user_username))
    error_message = "User_username must be a valid username: lowercase letters, digits, hyphens or underscores only, cannot start with a hyphen, and no spaces allowed."
  }
}

# Password for the standard user account.
# ***Required***: the build will fail if not provided.
variable "user_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.user_password) > 0
    error_message = "User_password is required. Provide a non-empty password."
  }
}

# ==============================================================
#  Proxmox device tuning
#  Network firewall, disk SSD mode/cache, and VGA settings.
# ==============================================================

# Enable Proxmox firewall on the VM NIC.
# Default: true (recommended for safer templates).
variable "nic_firewall" {
  type    = bool
  default = true
}

# Present the main disk as an SSD to the guest.
# Default: true (recommended for better scheduling/perf behavior and TRIM support).
variable "disk_ssd" {
  type    = bool
  default = true
}

# Disk cache mode (Proxmox setting).
# Default: "writeback" as requested.
# Allowed values are the typical Proxmox cache modes.
variable "disk_cache_mode" {
  type    = string
  default = "writeback"
  validation {
    condition     = contains(["none", "writethrough", "writeback", "directsync", "unsafe"], var.disk_cache_mode)
    error_message = "Disk_cache_mode must be one of: none, writethrough, writeback, directsync, unsafe."
  }
}

# VGA type used by Proxmox.
# Keep it restricted to values that are known to work without extra guest drivers.
# (virtio-gl is intentionally excluded because it can require additional guest-side drivers.)
variable "vga_type" {
  type    = string
  default = "virtio"
  validation {
    condition = contains([
      "std", "virtio", "virtio-gl", "vmware", "cirrus", "none",
      "qxl", "qxl2", "qxl3", "qxl4",
      "serial0", "serial1", "serial2", "serial3"
    ], var.vga_type)
    error_message = "Vga_type must be one of: std, virtio, virtio-gl, vmware, cirrus, none, qxl, qxl2, qxl3, qxl4, serial0, serial1, serial2, serial3."
  }
}

# VGA memory in MiB.
# Aligned with Linux configuration (256 MiB) for better display performance.
variable "vga_memory" {
  type    = number
  default = 256
  validation {
    condition     = var.vga_memory >= 4
    error_message = "Vga_memory must be at least 4 MiB."
  }
}
