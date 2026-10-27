# ==============================================================
#  QEMU builder — Debian 13 netinst → qcow2
#  Builds locally on the host via qemu-system-x86_64 + KVM.
#  Artefact: output-debian/<template_name>.qcow2
# ==============================================================

# Offline .deb set — shared with the Proxmox side to avoid duplicating
# qemu-guest-agent packages across hypervisor dirs. If the proxmox
# subtree is ever moved, update the relative path here.
locals {
  offline_debs_debian = fileset("${path.root}/../../proxmox/linux/offline/debian/debs", "*.deb")
}

source "qemu" "debian" {
  # --- VM identity & artefact ---
  vm_name          = "${var.template_name}.qcow2"
  output_directory = var.output_directory != "" ? var.output_directory : "output-${var.template_name}"
  format           = var.disk_format

  # --- Hardware ---
  cpus       = var.cpus * var.sockets   # Packer's qemu builder has a flat "cpus" (total vCPUs)
  memory     = var.memory
  disk_size  = var.disk_gb * 1024       # Packer's qemu builder takes MiB
  disk_interface = var.disk_interface
  net_device     = var.net_device

  # --- QEMU process settings ---
  accelerator       = var.qemu_accelerator
  headless          = var.qemu_headless
  vnc_bind_address  = var.qemu_vnc_bind_address
  vnc_port_min      = var.qemu_vnc_port_min
  vnc_port_max      = var.qemu_vnc_port_max

  # --- ISO ---
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  # --- HTTP server to serve preseed + offline .deb packages ---
  http_bind_address = "0.0.0.0"
  http_port_min     = 8200
  http_port_max     = 8299

  http_content = merge({
    "/preseed.cfg" = templatefile("${path.root}/http/debian/preseed.pkrtpl.hcl", {
      hostname      = var.template_name
      root_password = var.root_password
      user_username = var.user_username
      user_password = var.user_password
    })
    # Same %3a → _ substitution as the Proxmox side (see proxmox/linux/debian.pkr.hcl).
    "/debs/manifest.txt" = join("\n", [for f in local.offline_debs_debian : replace(f, "%3a", "_")])
  }, {
    for f in local.offline_debs_debian :
    "/debs/${replace(f, "%3a", "_")}.b64" => filebase64("${path.root}/../../proxmox/linux/offline/debian/debs/${f}")
  })

  # --- Automated boot sequence for Debian ---
  # Match the shape of the known-working Gemini test setup:
  #   1. Esc → boot: prompt
  #   2. explicit "install" label (safer than defaulting via Enter)
  #   3. preseed/url FIRST so the installer knows where to fetch early
  #   4. language=en country=FR locale=en_US.UTF-8 to bypass the "Select a
  #      country" screen that otherwise hangs headless installs
  #   5. keyboard-configuration/xkb-keymap=us for the install phase
  #      (fr is enforced inside the preseed for the FINAL system)
  #   6. fb=false + debconf/frontend=noninteractive for safety
  boot_wait = "15s"
  boot_command = [
    "<esc><wait>",
    "install ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "auto=true priority=critical ",
    "language=en country=FR locale=en_US.UTF-8 ",
    "keyboard-configuration/xkb-keymap=us ",
    "netcfg/choose_interface=auto ",
    "netcfg/get_hostname=${var.template_name} ",
    "netcfg/get_domain=local ",
    "fb=false ",
    "debconf/frontend=noninteractive ",
    "<enter>"
  ]

  # --- SSH communicator ---
  # Packer sets up a port forward on localhost → VM:22 automatically.
  communicator = "ssh"
  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout  = "60m"

  # --- Graceful shutdown ---
  # Packer connects as root (preseed enables it temporarily), so no sudo needed.
  shutdown_command = "shutdown -P now"
  shutdown_timeout = "10m"
}

# --- Build definition ---
build {
  name    = "debian"
  sources = ["source.qemu.debian"]

  # Harden SSH: deploy root key, enforce key-only root login.
  provisioner "shell" {
    inline = [
      "set -eux",

      "cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak || true",

      "install -d -m 700 /root/.ssh",
      "[ -n \"${var.root_ssh_pubkey}\" ] && printf '%s\n' \"${var.root_ssh_pubkey}\" > /root/.ssh/authorized_keys || true",
      "[ -f /root/.ssh/authorized_keys ] && chmod 600 /root/.ssh/authorized_keys || true",
      "chown -R root:root /root/.ssh",

      "sed -i 's/^#\\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config",
      "sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",

      "grep -q '^Include /etc/ssh/sshd_config.d/\\*' /etc/ssh/sshd_config || echo 'Include /etc/ssh/sshd_config.d/*' >> /etc/ssh/sshd_config",

      "install -d -m 755 /etc/ssh/sshd_config.d",
      "printf '%s\\n%s\\n' 'Match User root' '    PasswordAuthentication no' > /etc/ssh/sshd_config.d/90-root.conf",

      "sed -i '/^[[:space:]]*#\\?[[:space:]]*PermitRootLogin/d' /etc/ssh/sshd_config",
      "echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config",

      "sshd -t || (journalctl -u ssh --no-pager -n 100; exit 1)",
      "systemctl reload ssh || true",
    ]
  }
}
