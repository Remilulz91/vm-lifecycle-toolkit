# QEMU/KVM builder — local `.qcow2` images for libvirt / cockpit-machines

Third hypervisor track of the VM Lifecycle Toolkit, parallel to `proxmox/` and `esxi/`. Instead of pushing a VM to a remote hypervisor over an API, this track **builds the image locally** on your Linux machine via `qemu-system-x86_64` + KVM, and emits a plain `.qcow2` file that you then import into libvirt with `virt-install --import` — administrable visually through Cockpit (`cockpit-machines`).

## Prerequisites on the Packer host

The host that runs Packer **is** the KVM host.

```bash
# Core bits
sudo apt install packer qemu-system-x86 qemu-utils ovmf

# Enable + join the KVM / libvirt groups so your user can hit /dev/kvm
sudo adduser "$USER" kvm
sudo adduser "$USER" libvirt   # for virt-install later
# → log out / back in to pick up the new groups

# For visual administration via Cockpit
sudo apt install cockpit cockpit-machines libvirt-daemon-system virtinst
sudo systemctl enable --now cockpit.socket
# → http://<host>:9090
```

Check KVM is really available:

```bash
ls -l /dev/kvm              # should exist and be rw for the kvm group
kvm-ok || egrep -c '(vmx|svm)' /proc/cpuinfo   # non-zero = virtualization CPU flags are on
```

## Layout

```
hypervisors/qemu/
├── linux/
│   ├── plugins.pkr.hcl               # hashicorp/qemu plugin
│   ├── variables.pkr.hcl             # QEMU-side variables
│   ├── debian.pkr.hcl                # Debian source + build
│   ├── ubuntu.pkr.hcl                # Ubuntu source + build
│   └── http/
│       ├── debian/preseed.pkrtpl.hcl
│       └── ubuntu/user-data.pkrtpl.hcl
└── profiles/
    ├── site/qemu.pkrvars.hcl         # accelerator, headless, interfaces, output dir
    ├── os/
    │   ├── debian_13.pkrvars.hcl
    │   └── ubuntu_26_04_server.pkrvars.hcl
    └── flavors/
        ├── light.pkrvars.hcl
        ├── medium.pkrvars.hcl
        ├── hard.pkrvars.hcl
        └── extreme.pkrvars.hcl
```

The **offline `.deb` cache** (needed to install `qemu-guest-agent` without internet) is **shared with the Proxmox track** rather than duplicated here — the `.pkr.hcl` files reference `../../proxmox/linux/offline/{debian,ubuntu}/debs/`. One set of `.deb` files feeds both hypervisors.

## Build

```bash
cd hypervisors/qemu/linux

# Install the plugin (one-off)
packer init .

# Download the ISO once into a cache the Packer host can read.
# Example path matches profiles/os/debian_13.pkrvars.hcl.
sudo mkdir -p /var/cache/isos
sudo curl -L \
  https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso \
  -o /var/cache/isos/debian-13.5.0-amd64-DVD-1.iso
# Update iso_checksum in profiles/os/debian_13.pkrvars.hcl.

# Build Debian — medium flavor
packer build \
  -var-file=../profiles/site/qemu.pkrvars.hcl \
  -var-file=../profiles/os/debian_13.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_name=debian-13-qemu" \
  -var "root_password=TempPass123!" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=operator" \
  -var "user_password=TempPass123!" \
  debian.pkr.hcl
```

Artefact: `hypervisors/qemu/linux/output-debian-13-qemu/debian-13-qemu.qcow2`.

Same shape for Ubuntu (`ubuntu_26_04_server.pkrvars.hcl` + `ubuntu.pkr.hcl`).

### Watching the install

Default is headless. To watch the install happen, add `-var "qemu_headless=false"` (QEMU window pops up) or connect via VNC — Packer prints the VNC port in its logs.

## Import the `.qcow2` into libvirt / Cockpit

Once Packer is done:

```bash
# Move the image into a libvirt storage pool
sudo cp output-debian-13-qemu/debian-13-qemu.qcow2 /var/lib/libvirt/images/
sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/debian-13-qemu.qcow2

# Register and start the VM. --import = reuse an existing disk, no OS install.
sudo virt-install \
  --name debian-13-qemu \
  --memory 4096 --vcpus 2 \
  --disk path=/var/lib/libvirt/images/debian-13-qemu.qcow2,format=qcow2 \
  --os-variant debian13 \
  --network network=default,model=virtio \
  --import \
  --noautoconsole
```

The VM appears in **Cockpit → Virtual Machines** immediately. Console, lifecycle actions, snapshots and NICs are available from the web UI.

## Offline / air-gapped builds

1. Download the ISO on an online machine, verify the SHA-256, transfer it to the Packer/KVM host.
2. Point `iso_url` at the local file (`file:///path/to.iso`) in `profiles/os/<os>.pkrvars.hcl`.
3. The `offline/{debian,ubuntu}/debs/` directory under `hypervisors/proxmox/linux/` already holds the `.deb` files served by Packer's HTTP server during install — nothing to do on the QEMU side, those files are shared.

## Known limits

- **Linux only** in this release — Windows 11 on QEMU needs TPM 2.0 (swtpm), OVMF, Secure Boot keys. Planned as a follow-up (V3.8.1+).
- **Local build only** — the QEMU builder runs on the host executing Packer. Cross-host builds (build on A, deploy on B) are the Ansible side's job (`playbooks/configure-vm.yml`).
