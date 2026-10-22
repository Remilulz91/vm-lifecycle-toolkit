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

# Required: human-readable template name (also used as the Linux hostname,
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
    error_message = "Template_name must be a valid Linux hostname (1–63 chars, lowercase letters, digits, or hyphens, and must not start or end with a hyphen)."
  }
}

# ==============================================================
#  VM hardware resources
# ==============================================================

# vCPU count (generic, applies to all Linux templates)
variable "cpus" {
  type    = number
  default = 2
  validation {
    condition     = var.cpus >= 1
    error_message = "Cpus must be greater than or equal to 1."
  }
}

# RAM in MiB (generic lower bound to avoid unusable templates)
variable "memory" {
  type    = number
  default = 2048
  validation {
    condition     = var.memory >= 512
    error_message = "Memory must be at least 512 MiB."
  }
}

# System disk size in GB (generic minimum to keep room for OS and logs)
variable "disk_gb" {
  type    = number
  default = 20
  validation {
    condition     = var.disk_gb >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

# Number of CPU sockets (total vCPUs = sockets × cores)
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
#  Used by ISO-based installs (Debian/Ubuntu/RHEL).
# ==============================================================

# ESXi VMFS datastore that contains the installer ISO. Often the same as
# "datastore" above, but kept separate so ISOs can live on a dedicated datastore.
variable "iso_datastore" {
  type = string
}

# Path to the installer ISO inside the datastore (e.g., "iso/debian-13.5.0-amd64-DVD-1.iso").
variable "iso_file" {
  type = string
}

# ==============================================================
#  Accounts used inside the guest during/after installation
# ==============================================================

# Public SSH key content injected into /root/.ssh/authorized_keys by the provisioner.
# ***Required***: no default value — the build will fail if not provided.
variable "root_ssh_pubkey" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.root_ssh_pubkey) > 0
    error_message = "Root_ssh_pubkey is required. Provide it with -var \"root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)\"."
  }
}

# Temporary root password used during the Debian installation (via preseed)
# and the initial SSH connection before switching to key-only access.
# ***Required***: the build will fail if not provided.
variable "root_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.root_password) > 0
    error_message = "Root_password is required. Provide a non-empty temporary password."
  }
}

# --- Standard (non-sudo) user account ---
# Created by the Debian Installer via preseed.
# Must follow Linux username rules:
# - lowercase letters, digits, hyphens and underscores only
# - cannot start with a hyphen
# - no spaces, no uppercase
# - must be at least 1 character
variable "user_username" {
  type = string
  validation {
    condition = can(regex("^[a-z0-9_][-a-z0-9_]*$", var.user_username))
    error_message = "User_username must be a valid Linux username: lowercase letters, digits, hyphens or underscores only, cannot start with a hyphen, and no spaces allowed."
  }
}

variable "user_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.user_password) > 0
    error_message = "User_password is required. Provide a non-empty password."
  }
}
