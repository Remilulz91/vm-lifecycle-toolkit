# ==============================================================
#  QEMU builder — variables
#  Local qcow2 image generation via qemu-system-x86_64 + KVM.
#  No remote hypervisor involved: Packer builds entirely on the
#  host it runs on, and the artefact is a .qcow2 file that you
#  later import into libvirt with `virt-install --import`.
# ==============================================================

# ==============================================================
#  Template identity (required)
# ==============================================================

# Human-readable template name — used as the Linux hostname during
# install, and as the qcow2 filename (`<vm_name>.qcow2`).
variable "template_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.template_name))
    error_message = "Template_name must be a valid Linux hostname (1–63 chars, lowercase letters, digits, or hyphens, and must not start or end with a hyphen)."
  }
}

# ==============================================================
#  VM hardware resources (identical semantics to proxmox/)
# ==============================================================

variable "cpus" {
  type    = number
  default = 2
  validation {
    condition     = var.cpus >= 1
    error_message = "Cpus must be greater than or equal to 1."
  }
}

variable "sockets" {
  type    = number
  default = 1
  validation {
    condition     = var.sockets >= 1
    error_message = "Sockets must be 1 or greater."
  }
}

variable "memory" {
  type    = number
  default = 2048
  validation {
    condition     = var.memory >= 512
    error_message = "Memory must be at least 512 MiB."
  }
}

variable "disk_gb" {
  type    = number
  default = 20
  validation {
    condition     = var.disk_gb >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

# ==============================================================
#  QEMU-specific build settings
# ==============================================================

# ISO file — can be a `file:///absolute/path/to.iso` (recommended for
# offline/air-gapped builds) or an http(s) URL (download at build time).
variable "iso_url" {
  type = string
}

# Checksum for the ISO. Can be `sha256:<hash>`, `md5:<hash>`,
# `file:<path>`, or `none` (not recommended).
variable "iso_checksum" {
  type = string
}

# Output directory for the qcow2 artefact.
# Default follows Packer's convention: output-<vm_name>/
variable "output_directory" {
  type    = string
  default = ""
}

# QEMU accelerator. KVM is the default and strongly recommended on
# Linux hosts with /dev/kvm available. Set to "tcg" for software
# emulation on hosts without KVM (slow).
variable "qemu_accelerator" {
  type    = string
  default = "kvm"
  validation {
    condition     = contains(["kvm", "tcg", "hax", "hvf", "whpx", "none"], var.qemu_accelerator)
    error_message = "Qemu_accelerator must be one of: kvm, tcg, hax, hvf, whpx, none."
  }
}

# Run QEMU without a graphical display window.
# true = silent background build (recommended for CI/scripts).
# false = QEMU window pops up and you can watch the install.
variable "qemu_headless" {
  type    = bool
  default = true
}

# VNC bind address. Default 127.0.0.1 (loopback only, safe).
# Set to "0.0.0.0" to make the VNC port reachable from your workstation —
# useful for debugging when the install hangs headless. Combine with a
# fixed port range (qemu_vnc_port_min/max) so firewall rules are predictable.
variable "qemu_vnc_bind_address" {
  type    = string
  default = "127.0.0.1"
}

variable "qemu_vnc_port_min" {
  type    = number
  default = 5900
}

variable "qemu_vnc_port_max" {
  type    = number
  default = 5950
}

# Disk interface presented to the guest. virtio-scsi matches the
# Proxmox side; libvirt happily consumes the resulting qcow2 either way.
variable "disk_interface" {
  type    = string
  default = "virtio-scsi"
  validation {
    condition     = contains(["virtio", "virtio-scsi", "scsi", "ide"], var.disk_interface)
    error_message = "Disk_interface must be one of: virtio, virtio-scsi, scsi, ide."
  }
}

# NIC model presented to the guest. virtio-net is the fast path.
variable "net_device" {
  type    = string
  default = "virtio-net"
  validation {
    condition     = contains(["virtio-net", "e1000", "e1000e", "rtl8139"], var.net_device)
    error_message = "Net_device must be one of: virtio-net, e1000, e1000e, rtl8139."
  }
}

# Disk format for the output artefact. qcow2 is the only sensible
# choice for libvirt/cockpit-machines imports.
variable "disk_format" {
  type    = string
  default = "qcow2"
  validation {
    condition     = contains(["qcow2", "raw"], var.disk_format)
    error_message = "Disk_format must be qcow2 or raw."
  }
}

# ==============================================================
#  Accounts used inside the guest during/after installation
#  (identical semantics to proxmox/)
# ==============================================================

variable "root_ssh_pubkey" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.root_ssh_pubkey) > 0
    error_message = "Root_ssh_pubkey is required. Provide it with -var \"root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)\"."
  }
}

variable "root_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.root_password) > 0
    error_message = "Root_password is required. Provide a non-empty temporary password."
  }
}

variable "user_username" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9_][-a-z0-9_]*$", var.user_username))
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
