# ==============================================================
#  Proxmox ISO Source Configuration
#  Defines how Packer connects to Proxmox, creates the template,
#  and performs the automated Ubuntu installation.
# ==============================================================

# List of .deb files in the offline folder. They are served base64-encoded
# via Packer's HTTP server and installed by autoinstall's late-commands,
# providing packages (e.g. qemu-guest-agent) that are not on the install ISO.
locals {
  offline_debs_ubuntu = fileset("${path.root}/offline/ubuntu/debs", "*.deb")
}

source "proxmox-iso" "ubuntu" {
  # --- Authentication and connection ---
  proxmox_url              = var.proxmox_url           # Proxmox API endpoint (e.g. https://192.168.1.10:8006/api2/json)
  username                 = var.proxmox_token_id      # API token ID (e.g. packer@pam!ci)
  token                    = var.proxmox_token_secret  # Secret key associated with the API token
  insecure_skip_tls_verify = true                      # Skip TLS verification (useful for self-signed certificates)

  # --- Target template information ---
  node    = var.proxmox_node   # Proxmox node on which the template will be created (e.g., pve01)
  vm_id   = var.template_id    # Unique Proxmox VMID for this template
  vm_name = var.template_name  # Human-readable template name (used as hostname during install)

  # --- Hardware configuration ---
  memory   = var.memory        # Template RAM in MiB
  cores    = var.cpus          # Number of vCPUs per socket
  sockets  = var.sockets       # Number of CPU sockets (configurable via flavor)
  cpu_type = "host"            # Use host CPU for optimal performance
  os       = "l26"             # Linux 2.6+ kernel compatible (covers all modern Debian versions)

  # --- Storage controller and guest agent ---
  scsi_controller = "virtio-scsi-single"  # Use VirtIO SCSI single controller for better performance
  qemu_agent      = true                  # Enable QEMU Guest Agent (socket-activated service inside Debian)

  # --- Network configuration ---
  network_adapters {
    model    = "virtio"          # VirtIO provides high-performance paravirtualized networking
    bridge   = var.bridge        # Attach the template to the specified network bridge (e.g. vmbr0)
    firewall = var.nic_firewall  # Enable Proxmox firewall on this interface (default: true)
  }

  # --- Disk configuration ---
  disks {
    type         = "scsi"               # Disk interface type
    storage_pool = var.disk_storage_pool # Proxmox storage pool used for the main disk (e.g. local-lvm)
    disk_size    = "${var.disk_gb}G"    # Disk size (in GB)

    # Requested improvements
    ssd        = var.disk_ssd           # Present disk as SSD (default: true)
    cache_mode = var.disk_cache_mode    # Disk cache mode (default: writeback)
  }

  # --- Display configuration ---
  # VGA type is configurable, but restricted in variables.pkr.hcl to "safe" values.
  vga {
    type   = var.vga_type     # std, virtio, vmware, cirrus, qxl*, serial*, none (see validation)
    memory = var.vga_memory   # VGA memory in MiB (set via flavors)
  }

  # --- ISO configuration ---
  # You can either use an existing ISO on Proxmox or let Packer upload one.
  boot_iso {
    # ISO already available on Proxmox
    iso_file = "${var.iso_storage_pool}:${var.iso_file}"
    type     = "scsi"
    unmount  = true
  }

  # --- Lightweight HTTP server used by the Debian installer to fetch preseed ---
  # Bind on all interfaces so the VM can reach the host running Packer (Proxmox bridge, NAT, etc.).
  http_bind_address = "0.0.0.0"

  # Constrain the ephemeral port range to something predictable (helps with firewalls/visibility).
  http_port_min     = 8200
  http_port_max     = 8299

  # --- Dynamic autoinstall config and offline .deb packages served via Packer's HTTP server ---
  # user-data.pkrtpl.hcl is rendered with values from variables and published as
  # /user-data (with an empty /meta-data) for Subiquity's nocloud-net data source.
  # The .deb files in offline/ubuntu/debs/ are base64-encoded and published
  # under /debs/, to be downloaded and installed by autoinstall's late-commands
  # (so qemu-guest-agent is running when Packer queries the IP).
  http_content = merge({
    "/user-data" = templatefile("${path.root}/http/ubuntu/user-data.pkrtpl.hcl", {
      hostname      = var.template_name   # Debian hostname (also your template name)
      root_password = var.root_password   # Root password used by the installer
      user_username = var.user_username   # Standard user (non-sudoer)
      user_password = var.user_password   # Password for the standard user
    })
    "/meta-data" = ""
    # Replace %3a (URL-encoded ':') with '_': %3a doesn't match Packer's HTTP
    # server keys (it URL-decodes paths before lookup), and a literal ':' would
    # be misinterpreted by apt-get/dpkg as a package:arch qualifier.
    "/debs/manifest.txt" = join("\n", [for f in local.offline_debs_ubuntu : replace(f, "%3a", "_")])
  }, {
    for f in local.offline_debs_ubuntu :
    "/debs/${replace(f, "%3a", "_")}.b64" => filebase64("${path.root}/offline/ubuntu/debs/${f}")
  })

  # --- Automated boot sequence for Debian netinst ---
  # Packer types these keys at the boot prompt to start a fully unattended install.
  boot_wait = "15s"   # Small grace period to ensure the boot prompt is ready
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "<F10>"
  ]

  # --- SSH communicator ---
  # After installation, Packer connects to the template via SSH
  # using the root account and temporary credentials.
  communicator           = "ssh"             # Connection type
  ssh_username           = "root"            # Account created by preseed
  ssh_password           = var.root_password # Temporary password (later replaced by SSH key)
  ssh_port               = 22                # Default SSH port
  ssh_timeout            = "60m"             # Allow up to 60 minutes for initial SSH connection
}

# --- Build definition ---
# Minimal build: install qemu-guest-agent only, no cloud-init, no temp user cleanup.
build {
  name    = "ubuntu"                          # Build name (no cloud-init)
  sources = ["source.proxmox-iso.ubuntu"]     # Reference to the source

  # --- Provisioning phase ---
  # Installs the QEMU guest agent and enables it.
  provisioner "shell" {
    inline = [
      "set -eux",

      # SSH config backup
      "cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak || true",

      # Root key
      "install -d -m 700 /root/.ssh",
      "[ -n \"${var.root_ssh_pubkey}\" ] && printf '%s\n' \"${var.root_ssh_pubkey}\" > /root/.ssh/authorized_keys || true",
      "[ -f /root/.ssh/authorized_keys ] && chmod 600 /root/.ssh/authorized_keys || true",
      "chown -R root:root /root/.ssh",

      # Remove the temporary drop-in file used for installation (Ubuntu specific)
      "rm -f /etc/ssh/sshd_config.d/99-packer-ssh.conf",

      # SSH global: allow keys + password
      "sed -i 's/^#\\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config",
      "sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",

      # Ensure Include for drop-ins (usually present on Ubuntu 24)
      "grep -q '^Include /etc/ssh/sshd_config.d/\\*' /etc/ssh/sshd_config || echo 'Include /etc/ssh/sshd_config.d/*' >> /etc/ssh/sshd_config",

      # Root: key-only via drop-in
      "install -d -m 755 /etc/ssh/sshd_config.d",
      "printf '%s\\n%s\\n' 'Match User root' '    PasswordAuthentication no' > /etc/ssh/sshd_config.d/90-root.conf",

      # Clean duplicates of PermitRootLogin & enforce single correct line
      "sed -i '/^[[:space:]]*#\\?[[:space:]]*PermitRootLogin/d' /etc/ssh/sshd_config",
      "echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config",

      # Validate & reload
      "sshd -t || (journalctl -u ssh --no-pager -n 100; exit 1)",
      "systemctl reload ssh || true",
    ]
  }
}
