# ==============================================================
#  Proxmox ISO Source Configuration
#  Defines how Packer connects to Proxmox, creates the template,
#  and performs the automated Windows 11 installation.
# ==============================================================

source "proxmox-iso" "windows_11" {
  # --- Authentication and connection ---
  proxmox_url              = var.proxmox_url          # Proxmox API endpoint (e.g., https://pve:8006/api2/json)
  username                 = var.proxmox_token_id     # Proxmox API token ID (User)
  token                    = var.proxmox_token_secret # Secret key associated with the API token
  insecure_skip_tls_verify = true                     # Skips strict SSL certificate validation (useful for self-signed certs)

  # --- Target template information ---
  node    = var.proxmox_node   # The physical Proxmox node where the VM will be built
  vm_id   = var.template_id    # Unique Proxmox VMID for this template (e.g., 1004)
  vm_name = var.template_name  # Name of the template in the Proxmox UI

  # --- Hardware configuration ---
  memory   = var.memory        # Template RAM in MiB
  cores    = var.cpus          # Number of vCPUs per socket
  sockets  = var.sockets       # Number of CPU sockets
  cpu_type = "host"            # Exposes the host's CPU architecture directly for maximum performance
  os       = "win11"           # Tells Proxmox to use Windows 11 specific internal optimizations
  
  # --- UEFI BIOS & Machine Type (Mandatory for Windows 11) ---
  machine = "q35"              # Modern QEMU machine type supporting PCIe
  bios    = "ovmf"             # Enables UEFI BIOS instead of legacy SeaBIOS
  efi_config {
    efi_storage_pool  = var.disk_storage_pool # Where to store the EFI disk
    efi_type          = "4m"                  # Standard EFI disk size
    pre_enrolled_keys = true                  # Enables SecureBoot keys (Required by Windows 11)
  }

  # --- TPM 2.0 (Mandatory for Windows 11) ---
  tpm_config {
    tpm_storage_pool = var.disk_storage_pool # Where to store the TPM state drive
    tpm_version      = "v2.0"                # Windows 11 strictly requires TPM version 2.0
  }

  # --- FORCE BOOT ORDER ---
  # Boot priority: 1st is the Windows ISO (ide2), 2nd is the OS drive (scsi0).
  boot = "order=ide2;scsi0"

  # --- Storage controller and guest agent ---
  scsi_controller = "virtio-scsi-single" # High-performance SCSI controller for Proxmox
  qemu_agent      = true                 # Enables communication between Proxmox and the VM (IP reporting, shutdown)

  # --- Network configuration ---
  network_adapters {
    model    = "virtio"         # Paravirtualized network adapter (best performance). Needs drivers from VirtIO ISO.
    bridge   = var.bridge       # Proxmox network bridge (e.g., vmbr0)
    firewall = var.nic_firewall # Enables Proxmox firewall on this network interface
  }

  # --- Main OS Disk configuration ---
  disks {
    type         = "scsi"               # Paravirtualized disk (best performance). Needs drivers from VirtIO ISO.
    storage_pool = var.disk_storage_pool 
    disk_size    = "${var.disk_gb}G"    
    ssd          = var.disk_ssd         # Emulates an SSD to optimize Windows defragmentation behavior  
    cache_mode   = var.disk_cache_mode  # Disk caching strategy (usually writeback)
    discard      = true                 # Enables TRIM support for SSDs to reclaim unused space
  }

  # --- Display configuration ---
  vga {
    type   = var.vga_type     # Video adapter type (e.g., std, virtio)
    memory = var.vga_memory   # Video memory allocated to the VM
  }

  # --- CD-ROM 1: Main Windows 11 Installation ISO ---
  boot_iso {
    iso_file = "${var.iso_storage_pool}:${var.iso_file}"
    type     = "ide"   # Must be IDE for the UEFI BIOS to reliably boot from it
    index    = 2       # Mounts to ide2 (as referenced in the boot order)
    unmount  = true    # Automatically ejects the ISO before creating the final template
  }

  # --- CD-ROM 2: VirtIO Drivers ISO ---
  # Contains drivers for SCSI disks and VirtIO network adapters so Windows can see the hardware during setup.
  additional_iso_files {
    iso_file         = "${var.iso_storage_pool}:${var.virtio_iso_file}"
    type             = "sata"  # Mounted as a secondary SATA drive
    index            = 1
    unmount          = true    # Automatically ejects the ISO before creating the final template
  }

  # --- CD-ROM 3: Unattended Answer File (Autounattend.xml) ---
  # Packer dynamically generates a mini-ISO containing our XML file. 
  # Windows setup automatically scans for this file and uses it to perform a silent installation.
  additional_iso_files {
    cd_content = {
      "Autounattend.xml" = templatefile("${path.root}/http/windows_11/autounattend.pkrtpl.hcl", {
        # Windows strict rule: Hostnames cannot exceed 15 characters. 
        # substr() automatically truncates the template name to prevent silent installation crashes.
        hostname        = substr(var.template_name, 0, 15)
        
        # Dual-user strategy configuration passed to the XML file
        admin_username  = var.admin_username
        admin_password  = var.admin_password
        user_username   = var.user_username
        user_password   = var.user_password
      })
    }
    cd_label         = "winsetup" # CD Label expected by Windows
    iso_storage_pool = var.iso_storage_pool
    type             = "sata"     # Mounted as a secondary SATA drive
    index            = 2
    unmount          = true       # Automatically ejects the XML ISO before creating the final template
  }

  # --- CD-ROM 4: OpenSSH Server MSI (offline install) ---
  # Bundles the Win32-OpenSSH MSI so the autounattend can install OpenSSH Server
  # without reaching the Windows Update / Features on Demand CDN.
  additional_iso_files {
    cd_files         = ["${path.root}/offline/OpenSSH-Win64.msi"]
    cd_label         = "openssh"
    iso_storage_pool = var.iso_storage_pool
    type             = "sata"     # Mounted as a secondary SATA drive
    index            = 3
    unmount          = true       # Automatically ejects the MSI ISO before creating the final template
  }

  # --- Automated boot sequence for Windows 11 ---
  boot_wait = "1s" # Start typing almost immediately after VM boot
  boot_command = [
    # Windows ISOs prompt with "Press any key to boot from CD or DVD...".
    # We spam the spacebar repeatedly for ~15 seconds to ensure we hit the prompt,
    # regardless of how long the Proxmox VNC console takes to open.
    "<space><wait><space><wait><space><wait><space><wait><space><wait>",
    "<space><wait><space><wait><space><wait><space><wait><space><wait>"
  ]

  # --- SSH communicator ---
  # Packer uses SSH (not WinRM) to connect to the Windows machine once installation is complete.
  communicator           = "ssh"             
  ssh_username           = var.admin_username # Packer logs in as the Administrator ('root' equivalent)
  ssh_password           = var.admin_password # Temporary password used to establish the first connection
  ssh_port               = 22                
  ssh_timeout            = "2h"               # Windows setup takes multiple reboots and a long time, so we wait up to 2 hours.
}

# --- Build definition ---
build {
  name    = "windows_11"                               
  sources = ["source.proxmox-iso.windows_11"]     

  # --- Post-Installation Provisioning phase ---
  # This step runs via SSH after Windows reaches the desktop.
  # We removed the strict SSH key-only restriction to allow password logins.
  provisioner "powershell" {
    inline = [
      "Write-Output '--- Starting Windows Provisioning ---'",
      "Write-Output 'SSH connection established successfully!'",
      "Write-Output 'Administrator and Standard User are ready for password or key-based login.'"
    ]
  }
}
