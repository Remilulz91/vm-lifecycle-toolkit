# ==============================================================
#  vSphere ISO Source Configuration
#  Defines how Packer connects to ESXi, creates the template,
#  and performs the automated Debian installation.
# ==============================================================

# List of .deb files in the offline folder. They are served base64-encoded
# via Packer's HTTP server and installed by the preseed's late_command,
# providing packages (e.g. open-vm-tools) that are not on the Debian DVD-1.
locals {
  offline_debs = fileset("${path.root}/offline/debian/debs", "*.deb")
}

source "vsphere-iso" "debian" {
  # --- Authentication and connection ---
  vcenter_server      = var.vsphere_url      # ESXi host URL or IP (e.g. 192.168.10.253)
  host                = var.vsphere_host     # Hostname of the ESXi as it appears in the vSphere inventory
  username            = var.vsphere_username # User authenticating to ESXi (typically "root")
  password            = var.vsphere_password # Password (passed via -var at build time)
  insecure_connection = true                 # Skip TLS verification (ESXi uses a self-signed cert)

  # --- Target template information ---
  vm_name             = var.template_name   # Human-readable template name (used as hostname during install)
  guest_os_type       = "debian13_64Guest"  # vSphere guest OS identifier for Debian 13 (64-bit, requires ESXi 8.0u3+)
  convert_to_template = false               # ESXi 8.0+ standalone has effectively dropped template support
                                            # in the UI (no MarkAsTemplate API, no Convert-to-Template action,
                                            # no Deploy-from-Template). The build leaves a powered-off VM you
                                            # use directly as the "golden image" — to clone, use the ESXi UI's
                                            # "Export" then "Create / Register VM > Deploy from OVF/OVA"
                                            # workflow. Set to true if you later move to a vCenter-managed setup.

  # --- Hardware configuration ---
  RAM                  = var.memory             # Template RAM in MiB
  CPUs                 = var.sockets * var.cpus # Total number of vCPUs (sockets × cores per socket).
                                                # vsphere-iso v2.x maps this directly to vSphere's
                                                # numCPUs (total), so we compute it explicitly.
  cpu_cores            = var.cpus               # Number of CPU cores per socket
  disk_controller_type = ["pvscsi"]             # Paravirtualized SCSI controller (best performance, requires VMware Tools)

  # --- Network configuration ---
  network_adapters {
    network      = var.network # Portgroup the template attaches to (e.g. "VM Network")
    network_card = "e1000e"    # Emulated NIC. Slightly lower throughput than "vmxnet3" but more stable,
                               # natively supported by every modern OS without VMware Tools, and aligned
                               # with the enterprise standard used across all our ESXi VMs.
  }

  # --- Disk configuration ---
  # Datastore where the VM (config files + disk) is placed.
  datastore = var.datastore
  storage {
    disk_size             = var.disk_gb * 1024 # Disk size in MB (vsphere-iso expects megabytes)
    disk_thin_provisioned = true               # Thin provisioning: only uses space as data is written
  }

  # --- ISO configuration ---
  # ISO already available on the ESXi datastore (uploaded manually).
  iso_paths = ["[${var.iso_datastore}] ${var.iso_file}"]

  # --- Lightweight HTTP server used by the Debian installer to fetch preseed ---
  # Bind on all interfaces so the VM can reach the host running Packer.
  http_bind_address = "0.0.0.0"

  # Constrain the ephemeral port range to something predictable (helps with firewalls/visibility).
  http_port_min     = 8200
  http_port_max     = 8299

  # --- Dynamic preseed and offline .deb packages served via Packer's HTTP server ---
  # preseed.pkrtpl.hcl is rendered with values from variables and published as
  # /preseed.cfg. The .deb files in offline/debian/debs/ are base64-encoded and
  # published under /debs/, to be downloaded and installed by the preseed's
  # late_command (so open-vm-tools is running when Packer queries the IP).
  http_content = merge({
    "/preseed.cfg" = templatefile("${path.root}/http/debian/preseed.pkrtpl.hcl", {
      hostname      = var.template_name   # Debian hostname (also your template name)
      root_password = var.root_password   # Root password used by the installer
      user_username = var.user_username   # Standard user (non-sudoer)
      user_password = var.user_password   # Password for the standard user
    })
    # Replace %3a (URL-encoded ':') with '_': %3a doesn't match Packer's HTTP
    # server keys (it URL-decodes paths before lookup), and a literal ':' would
    # be misinterpreted by apt-get as a package:arch qualifier.
    "/debs/manifest.txt" = join("\n", [for f in local.offline_debs : replace(f, "%3a", "_")])
  }, {
    for f in local.offline_debs :
    "/debs/${replace(f, "%3a", "_")}.b64" => filebase64("${path.root}/offline/debian/debs/${f}")
  })

  # --- Automated boot sequence for Debian netinst ---
  # Packer types these keys at the boot prompt to start a fully unattended install.
  boot_wait = "15s"   # Small grace period to ensure the boot prompt is ready
  boot_command = [
    "<esc><wait>",

    # Non-interactive installer with highest priority (no dialogs)
    "auto priority=critical ",

    # Installer language = English, system locale = en_US.UTF-8
    "locale=en_US.UTF-8 debian-installer=en_US ",

    # French keyboard only (AZERTY)
    "kbd-chooser/method=fr keyboard-configuration/xkb-keymap=fr ",

    # Make sure networking comes up automatically so the VM can reach Packer's HTTP server
    "netcfg/choose_interface=auto ",
    "netcfg/disable_dhcp=false ",
    "ip=dhcp ",

    # Hostname provided to the installer (no domain)
    "netcfg/get_hostname=${var.template_name} ",

    # Tell the installer where to fetch the rendered preseed
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",

    # Kick it off
    "<enter>"
  ]

  # --- SSH communicator ---
  # After installation, Packer connects to the template via SSH
  # using the root account and temporary credentials.
  communicator           = "ssh"             # Connection type
  ssh_username           = "root"            # Account created by preseed
  ssh_password           = var.root_password # Temporary password (later replaced by SSH key)
  ssh_port               = 22                # Default SSH port
  ssh_timeout            = "60m"             # Allow up to 60 minutes for initial SSH connection

  # --- Graceful shutdown ---
  # vsphere-iso has no reliable default shutdown for Linux guests; we explicitly
  # call poweroff via SSH so the VM is powered off before convert_to_template.
  shutdown_command = "poweroff"
}

# --- Build definition ---
# Minimal build: only post-install SSH hardening (root keys, key-only auth).
build {
  name    = "debian"                          # Build name (no cloud-init)
  sources = ["source.vsphere-iso.debian"]     # Reference to the source

  # --- Provisioning phase ---
  # Hardens SSH: deploys the root key and enforces key-only login for root.
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

    # SSH global: allow keys + password
    "sed -i 's/^#\\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",

    # Ensure Include for drop-ins (usually present on Debian 13)
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
