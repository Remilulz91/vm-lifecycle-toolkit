# ==============================================================
#  QEMU builder — Ubuntu Server (autoinstall / cloud-init) → qcow2
#  Builds locally on the host via qemu-system-x86_64 + KVM.
#  Artefact: output-ubuntu/<template_name>.qcow2
# ==============================================================

locals {
  offline_debs_ubuntu = fileset("${path.root}/../../proxmox/linux/offline/ubuntu/debs", "*.deb")
}

source "qemu" "ubuntu" {
  # --- VM identity & artefact ---
  vm_name          = "${var.template_name}.qcow2"
  output_directory = var.output_directory != "" ? var.output_directory : "output-${var.template_name}"
  format           = var.disk_format

  # --- Hardware ---
  cpus       = var.cpus * var.sockets
  memory     = var.memory
  disk_size  = var.disk_gb * 1024
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

  # --- HTTP server to serve autoinstall config + offline .deb packages ---
  http_bind_address = "0.0.0.0"
  http_port_min     = 8200
  http_port_max     = 8299

  http_content = merge({
    "/user-data" = templatefile("${path.root}/http/ubuntu/user-data.pkrtpl.hcl", {
      hostname      = var.template_name
      root_password = var.root_password
      user_username = var.user_username
      user_password = var.user_password
    })
    "/meta-data" = ""
    "/debs/manifest.txt" = join("\n", [for f in local.offline_debs_ubuntu : replace(f, "%3a", "_")])
  }, {
    for f in local.offline_debs_ubuntu :
    "/debs/${replace(f, "%3a", "_")}.b64" => filebase64("${path.root}/../../proxmox/linux/offline/ubuntu/debs/${f}")
  })

  # --- Automated boot sequence for Ubuntu autoinstall ---
  # The autoinstall ds=nocloud-net snippet points Subiquity at Packer's HTTP
  # server for user-data + meta-data. GRUB's `e` key opens the kernel-line
  # editor; we move to the end of the linux line and append the ds= value.
  boot_wait = "15s"
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "<F10>"
  ]

  # --- SSH communicator ---
  communicator = "ssh"
  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout  = "60m"

  # --- Graceful shutdown ---
  # Packer connects as root (user-data enables it temporarily), so no sudo needed.
  shutdown_command = "shutdown -P now"
  shutdown_timeout = "10m"
}

build {
  name    = "ubuntu"
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = [
      "set -eux",

      "cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak || true",

      "install -d -m 700 /root/.ssh",
      "[ -n \"${var.root_ssh_pubkey}\" ] && printf '%s\n' \"${var.root_ssh_pubkey}\" > /root/.ssh/authorized_keys || true",
      "[ -f /root/.ssh/authorized_keys ] && chmod 600 /root/.ssh/authorized_keys || true",
      "chown -R root:root /root/.ssh",

      # Remove the temporary drop-in file used for installation (Ubuntu specific)
      "rm -f /etc/ssh/sshd_config.d/99-packer-ssh.conf",

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
