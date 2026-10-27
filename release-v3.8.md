# V3.8 — Third hypervisor: QEMU/KVM → local `.qcow2`

Adds a `hypervisors/qemu/` track alongside `proxmox/` and `esxi/`. Instead of pushing a VM to a remote hypervisor over an API, this one **builds locally** on the host running Packer, via `qemu-system-x86_64` + KVM, and emits a plain **`.qcow2`** file you then import into libvirt with `virt-install --import` — administrable visually through Cockpit (`cockpit-machines`).

## Scope

- **OS**: Debian 13, Ubuntu 26.04 Server (same preseed / autoinstall as the Proxmox side).
- **Local build only** — the Packer host is also the KVM host.
- **Headless by default** — flip `qemu_headless=false` to watch the install.
- **Linux only** in this release. Windows 11 on QEMU needs TPM 2.0 (swtpm) + OVMF + Secure Boot keys and is planned as V3.8.1+.

## New files

```
hypervisors/qemu/
├── linux/
│   ├── plugins.pkr.hcl              # hashicorp/qemu ≥ 1.1.0
│   ├── variables.pkr.hcl            # qemu-specific vars (no proxmox/vsphere)
│   ├── debian.pkr.hcl               # qemu source + build
│   ├── ubuntu.pkr.hcl               # qemu source + build
│   └── http/
│       ├── debian/preseed.pkrtpl.hcl
│       └── ubuntu/user-data.pkrtpl.hcl
└── profiles/
    ├── site/qemu.pkrvars.hcl        # accelerator, headless, interfaces, output dir
    ├── os/debian_13.pkrvars.hcl
    ├── os/ubuntu_26_04_server.pkrvars.hcl
    └── flavors/{light,medium,hard,extreme}.pkrvars.hcl
```

Build instructions are in the top-level `BUILD.md` (Step 5ter — same format as Proxmox / ESXi), not in a per-hypervisor README.

## Design notes

- **ISO sourcing** — `profiles/os/*.pkrvars.hcl` uses `iso_url` + `iso_checksum`. Supports both `file:///…` (recommended for offline sites: download once, verify SHA-256, reference the local copy) and `https://…` (Packer fetches to its cache on first build).
- **Offline `.deb` cache shared with Proxmox** — rather than duplicating the `qemu-guest-agent` package set, the QEMU `.pkr.hcl` files reference `../../proxmox/linux/offline/{debian,ubuntu}/debs/`. One set of files feeds both hypervisors.
- **SSH during build** — Packer's QEMU builder sets up a localhost port-forward to the guest's :22 automatically. No virtual network tweaks required.
- **Same preseed / autoinstall templates** as the Proxmox side (locale, keyboard, timezone, partitioning, SSH hardening). Hypervisor-neutral by construction.

## Typical workflow

```bash
# Prereqs on the Packer host (one-off)
sudo apt install packer qemu-system-x86 qemu-utils ovmf
sudo adduser "$USER" kvm   # log out / back in

cd hypervisors/qemu/linux
packer init .

# Grab the ISO once, update profiles/os/debian_13.pkrvars.hcl with its SHA-256
sudo mkdir -p /var/cache/isos
sudo curl -L \
  https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso \
  -o /var/cache/isos/debian-13.5.0-amd64-DVD-1.iso

# Build — matches the Proxmox / ESXi call shape: give Packer the directory (".")
# and scope to one OS with -only=<build>.*
PACKER_LOG=1 packer build \
  -only="debian.*" \
  -var-file=../profiles/site/qemu.pkrvars.hcl \
  -var-file=../profiles/os/debian_13.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_name=tpl-debian13-qemu" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  .

# Import into libvirt (visible in Cockpit → Virtual Machines immediately)
sudo cp output-tpl-debian13-qemu/tpl-debian13-qemu.qcow2 /var/lib/libvirt/images/
sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/tpl-debian13-qemu.qcow2

sudo virt-install \
  --name tpl-debian13-qemu --memory 4096 --vcpus 2 \
  --disk path=/var/lib/libvirt/images/tpl-debian13-qemu.qcow2,format=qcow2 \
  --os-variant debian13 --network network=default,model=virtio \
  --import --noautoconsole
```

## Not included (planned)

- V3.8.1 — Windows 11 on QEMU (TPM 2.0 via swtpm, OVMF, Secure Boot).
- V3.9+ — Terraform side (user asked to defer; coming later).
