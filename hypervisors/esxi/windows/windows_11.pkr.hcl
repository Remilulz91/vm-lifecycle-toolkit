# ==============================================================
#  vSphere ISO Source Configuration
#  Defines how Packer connects to ESXi, creates the template,
#  and performs the automated Windows 11 installation.
# ==============================================================

source "vsphere-iso" "windows_11" {
  # --- Authentication and connection ---
  vcenter_server      = var.vsphere_url      # ESXi host URL or IP (e.g. 192.168.10.253)
  host                = var.vsphere_host     # Hostname of the ESXi as it appears in the vSphere inventory
  username            = var.vsphere_username # User authenticating to ESXi (typically "root")
  password            = var.vsphere_password # Password (passed via -var at build time)
  insecure_connection = true                 # Skip TLS verification (ESXi uses a self-signed cert)

  # --- Target template information ---
  vm_name             = var.template_name   # Human-readable template name (also Windows hostname, max 15 chars)
  guest_os_type       = "windows11_64Guest" # vSphere guest OS identifier for Windows 11 (64-bit)
  convert_to_template = false               # ESXi 8.0+ standalone has effectively dropped template support
                                            # in the UI (no MarkAsTemplate API, no Convert-to-Template action,
                                            # no Deploy-from-Template). The build leaves a powered-off VM you
                                            # use directly as the "golden image" — to clone, use the ESXi UI's
                                            # "Export" then "Create / Register VM > Deploy from OVF/OVA"
                                            # workflow. Set to true if you later move to a vCenter-managed setup.

  # --- Hardware configuration ---
  RAM                  = var.memory                # Template RAM in MiB
  CPUs                 = var.sockets * var.cpus    # Total number of vCPUs (sockets × cores per socket).
                                                   # vsphere-iso v2.x maps this directly to vSphere's
                                                   # numCPUs (total), so we compute it explicitly.
  cpu_cores            = var.cpus                  # Number of CPU cores per socket
  disk_controller_type = ["lsilogic-sas"]          # SCSI controller with built-in Windows drivers (no driver injection needed)

  # --- UEFI + Secure Boot (mandatory for Windows 11) ---
  # vTPM is intentionally not enabled here: it would require a Key Provider
  # (Native Key Provider) configured on the ESXi host. Instead, the autounattend
  # uses LabConfig registry keys to bypass the TPM check during install.
  firmware = "efi-secure" # UEFI BIOS with Secure Boot enabled

  # --- Network configuration ---
  network_adapters {
    network      = var.network # Portgroup the template attaches to (e.g. "VM Network")
    network_card = "e1000e"    # Network adapter with built-in Windows drivers
  }

  # --- Disk configuration ---
  # Datastore where the VM (config files + disk) is placed.
  datastore = var.datastore
  storage {
    disk_size             = var.disk_gb * 1024 # Disk size in MB (vsphere-iso expects megabytes)
    disk_thin_provisioned = true               # Thin provisioning: only uses space as data is written
  }

  # --- ISOs available during install ---
  # Both ISOs must be uploaded manually to the ESXi datastore beforehand.
  # 1. Windows 11 install ISO (boots Windows setup).
  # 2. VMware Tools ISO (used by autounattend FirstLogonCommands to install VMware Tools post-OS).
  iso_paths = [
    "[${var.iso_datastore}] ${var.iso_file}",
    "[${var.iso_datastore}] ${var.vmware_tools_iso_file}",
  ]

  # --- Generated CD-ROM (autounattend + OpenSSH MSI) ---
  # Packer creates a small ISO containing:
  #   - Autounattend.xml (rendered template, Windows setup auto-detects it on any CD).
  #   - OpenSSH-Win64.msi (installed by autounattend FirstLogonCommands).
  cd_label = "winsetup"
  cd_content = {
    "Autounattend.xml" = templatefile("${path.root}/http/windows_11/autounattend.pkrtpl.hcl", {
      # Windows strict rule: Hostnames cannot exceed 15 characters.
      # substr() automatically truncates the template name to prevent silent installation crashes.
      hostname = substr(var.template_name, 0, 15)

      # Dual-user strategy configuration passed to the XML file
      admin_username = var.admin_username
      admin_password = var.admin_password
      user_username  = var.user_username
      user_password  = var.user_password
    })
  }
  cd_files = ["${path.root}/offline/OpenSSH-Win64.msi"]

  # --- Automated boot sequence for Windows 11 ---
  boot_wait = "1s" # Start typing almost immediately after VM boot
  boot_command = [
    # Windows ISOs prompt with "Press any key to boot from CD or DVD...".
    # We spam the spacebar repeatedly for ~15 seconds to ensure we hit the prompt,
    # regardless of how long the ESXi console takes to open.
    "<space><wait><space><wait><space><wait><space><wait><space><wait>",
    "<space><wait><space><wait><space><wait><space><wait><space><wait>"
  ]

  # --- SSH communicator ---
  # Packer uses SSH (not WinRM) to connect to the Windows machine once installation is complete.
  communicator           = "ssh"
  ssh_username           = var.admin_username # Packer logs in as the Administrator ('root' equivalent)
  ssh_password           = var.admin_password # Temporary password used to establish the first connection
  ssh_port               = 22
  ssh_timeout            = "2h" # Windows setup takes multiple reboots and a long time, so we wait up to 2 hours.

  # --- Graceful shutdown ---
  # vsphere-iso has no reliable default shutdown for Windows guests; we explicitly
  # call Windows shutdown via cmd so the VM is powered off before convert_to_template.
  shutdown_command = "shutdown /s /t 0 /f"
}

# --- Build definition ---
build {
  name    = "windows_11"
  sources = ["source.vsphere-iso.windows_11"]

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
