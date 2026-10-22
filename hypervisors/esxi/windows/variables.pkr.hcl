# ==============================================================
#  vSphere/ESXi API & SSH connection variables
#  Used by Packer to authenticate to the standalone ESXi host.
# ==============================================================

# ESXi host URL or IP (just the host — no /api path).
# Example: "esxi01.lan" or "192.168.10.50"
variable "vsphere_url" {
  type = string
}

# Username used to authenticate against the ESXi host
# (typically "root" for standalone ESXi, or a dedicated service account).
# Example: "root"
variable "vsphere_username" {
  type = string
}

# Password for the user above. Marked sensitive so it won't leak in logs.
variable "vsphere_password" {
  type      = string
  sensitive = true
}

# Hostname of the ESXi host as it appears in the vSphere inventory.
# For standalone ESXi this is the host's configured hostname (e.g. "localhost.localdomain"
# if no FQDN was set at install time, or "esxi01.lan" for a custom hostname).
# Distinct from vsphere_url, which is the network endpoint for the API connection.
variable "vsphere_host" {
  type = string
}

# ==============================================================
#  Template identity (required)
# ==============================================================

# Required: Human-readable template name (also used as the OS hostname,
# and as the VM name on the ESXi host).
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

# ESXi VMFS datastore used for the VM disk (e.g., "datastore1").
variable "datastore" {
  type = string
}

# ESXi portgroup used for the VM NIC (e.g., "VM Network").
variable "network" {
  type = string
}

# ==============================================================
#  ISO source (generic)
#  Used by ISO-based installs (Windows).
# ==============================================================

# ESXi VMFS datastore that contains the installer ISO. Often the same as
# "datastore" above, but kept separate so ISOs can live on a dedicated datastore.
variable "iso_datastore" {
  type = string
}

# Path to the installer ISO inside the datastore (e.g., "iso/Win11_25H2_French_x64.iso").
variable "iso_file" {
  type = string
}

# Path to the VMware Tools installer ISO inside the datastore, mounted as
# a secondary CD-ROM so the autounattend FirstLogonCommands can install
# VMware Tools post-OS install (needed for IP reporting to ESXi, time sync, etc.).
# Example: "iso/VMware-tools-windows.iso"
variable "vmware_tools_iso_file" {
  type = string
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
