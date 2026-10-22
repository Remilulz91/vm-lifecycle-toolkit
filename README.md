# 🧱 VM Lifecycle Toolkit — Build & Deploy VMs on Proxmox and ESXi

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v3.6-blue.svg)](README.md)
[![Packer](https://img.shields.io/badge/Packer-%E2%89%A51.11.0-blueviolet.svg)](https://www.packer.io/)
[![Hypervisors](https://img.shields.io/badge/Hypervisors-Proxmox%20%7C%20ESXi-orange.svg)](README.md)
[![OSes](https://img.shields.io/badge/OSes-Debian%20%7C%20Ubuntu%20%7C%20Windows%2011-green.svg)](README.md)
[![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)](README.md)

This project is a **multi-tool, multi-hypervisor automation stack** for the full VM lifecycle: **building templates with HashiCorp Packer** today (`hypervisors/` directory), with planned **VM cloning and configuration via Ansible and Terraform** on top of those templates (`ansible/` and `terraform/` sibling directories, coming later).

The Packer side includes complete working implementations for **Debian 13**, **Ubuntu Server (26.04 on Proxmox, 24.04 LTS on ESXi)**, **Ubuntu Desktop (Proxmox only — see Known Limitations)**, and **Windows 11** on both **Proxmox VE** and **VMware ESXi** (standalone). The repository structure is prepared for additional OS families (**Rocky Linux**, **RHEL**, etc.) and for the planned sibling directories.

# 🚀 Features

- ✅ Fully unattended Debian installation using **templated preseed** (`preseed.pkrtpl.hcl`)
- ✅ Fully unattended Ubuntu installation using **Subiquity / Autoinstall** (`user-data.pkrtpl.hcl`)
- ✅ Fully unattended Windows 11 installation bypassing OOBE/TPM using **answer files** (`autounattend.pkrtpl.hcl`)
- ✅ Consistent SSH connectivity across all OSes (Native OpenSSH used for Windows instead of WinRM)
- ✅ Root / Admin SSH key-only authentication (password removed/disabled after provisioning)
- ✅ Standard user creation (password-based login allowed locally)
- ✅ Guest tools auto-installed: QEMU Guest Agent on Proxmox, open-vm-tools / VMware Tools on ESXi
- ✅ Clean & idempotent SSH configuration
- ✅ Dynamic **template_id** (Proxmox), **template_name**, and hardware variables
- ✅ Automatic conversion of the VM into a Proxmox template (ESXi standalone is not capable — see Known Limitations)
- ✅ Repository structure designed for **multi-OS** and **multi-hypervisor** (**Proxmox** + **ESXi**) builds

---

# 📁 Repository Layout (V3.6 — Multi-OS, Multi-Hypervisor, Multi-Tool)

```bash
vm-lifecycle-toolkit/
├─ hypervisors/                                 ← V3.6: Packer VM template builders grouped here
│  ├─ esxi/                                     ← V3.5: full ESXi standalone support
│  │  ├─ linux/
│  │  │  ├─ http/
│  │  │  │  ├─ debian/
│  │  │  │  │  └─ preseed.pkrtpl.hcl
│  │  │  │  └─ ubuntu/
│  │  │  │     └─ user-data.pkrtpl.hcl
│  │  │  ├─ offline/
│  │  │  │  └─ debian/
│  │  │  │     └─ debs/                          (local .deb packages, not committed)
│  │  │  ├─ plugins.pkr.hcl                      (vsphere plugin)
│  │  │  ├─ debian.pkr.hcl
│  │  │  ├─ ubuntu.pkr.hcl
│  │  │  └─ variables.pkr.hcl
│  │  │
│  │  ├─ windows/
│  │  │  ├─ http/
│  │  │  │  └─ windows_11/
│  │  │  │     └─ autounattend.pkrtpl.hcl
│  │  │  ├─ offline/                             (OpenSSH-Win64.msi, not committed)
│  │  │  ├─ plugins.pkr.hcl                      (vsphere plugin)
│  │  │  ├─ windows_11.pkr.hcl
│  │  │  └─ variables.pkr.hcl
│  │  │
│  │  └─ profiles/
│  │     ├─ site/
│  │     │   └─ esxi.pkrvars.hcl
│  │     ├─ os/
│  │     │   ├─ debian_13.pkrvars.hcl
│  │     │   ├─ ubuntu_24_04_server.pkrvars.hcl
│  │     │   ├─ ubuntu_24_04_desktop.pkrvars.hcl   (KNOWN BROKEN — see Limitations)
│  │     │   └─ windows_11.pkrvars.hcl
│  │     └─ flavors/
│  │         ├─ light.pkrvars.hcl
│  │         ├─ medium.pkrvars.hcl
│  │         ├─ hard.pkrvars.hcl
│  │         └─ extreme.pkrvars.hcl
│  │
│  └─ proxmox/                                   ← V3.4 implementation
│     ├─ linux/
│     │  ├─ http/
│     │  │  ├─ debian/
│     │  │  │  └─ preseed.pkrtpl.hcl
│     │  │  └─ ubuntu/
│     │  │     └─ user-data.pkrtpl.hcl
│     │  ├─ offline/
│     │  │  ├─ debian/
│     │  │  │  └─ debs/                          (local .deb packages, not committed)
│     │  │  └─ ubuntu/
│     │  │     └─ debs/                          (local .deb packages, not committed)
│     │  ├─ plugins.pkr.hcl                      (proxmox plugin)
│     │  ├─ debian.pkr.hcl
│     │  ├─ ubuntu.pkr.hcl
│     │  └─ variables.pkr.hcl
│     │
│     ├─ windows/
│     │  ├─ http/
│     │  │  └─ windows_11/
│     │  │     └─ autounattend.pkrtpl.hcl
│     │  ├─ offline/                             (OpenSSH Server MSI, not committed)
│     │  ├─ plugins.pkr.hcl                      (proxmox plugin)
│     │  ├─ windows_11.pkr.hcl
│     │  └─ variables.pkr.hcl
│     │
│     └─ profiles/
│        ├─ site/
│        │   └─ proxmox.pkrvars.hcl
│        ├─ os/
│        │   ├─ debian_13.pkrvars.hcl
│        │   ├─ ubuntu_26_04_server.pkrvars.hcl
│        │   ├─ ubuntu_26_04_desktop.pkrvars.hcl
│        │   └─ windows_11.pkrvars.hcl
│        └─ flavors/
│            ├─ light.pkrvars.hcl
│            ├─ medium.pkrvars.hcl
│            ├─ hard.pkrvars.hcl
│            └─ extreme.pkrvars.hcl
│
├─ ansible/                                     ← [Planned V3.7+] VM configuration & cloning via Ansible
├─ terraform/                                   ← [Planned V3.7+] VM cloning via Terraform
├─ LICENSE
└─ README.md
```

✔ What changed in V3.6?

- **Repository restructured** to prepare for a broader multi-tool scope:
  - `proxmox/` and `esxi/` moved under a new `hypervisors/` top-level directory.
  - `ansible/` and `terraform/` placeholder directories planned at the top level for VM cloning / configuration workflows (not yet populated).
- **Project renamed** from `packer-proxmox-builder` to `vm-lifecycle-toolkit` to reflect the broader scope that extends beyond Packer-only template building.
- **LICENSE** switched from MIT (Safran Data Systems) to proprietary (Rémi Rousselot) with viewing-only terms, in preparation for public GitHub publication.
- Removed empty RHEL scaffolding (`rhel.pkr.hcl` and `http/rhel/kickstart.ks.pkrtpl.hcl`) from both hypervisor trees after review feedback.

✔ What changed in V3.5?

- Added **complete ESXi standalone support** mirroring the Proxmox structure, originally under a top-level `esxi/` directory (moved under `hypervisors/esxi/` in V3.6).
- New ESXi source blocks use the official `hashicorp/vsphere` plugin (vsphere-iso builder), UEFI Secure Boot firmware for Ubuntu and Windows, `lsilogic-sas`/`pvscsi` SCSI controllers, and `e1000e` paravirtualised NICs (aligned with common enterprise standards).
- New Debian build on ESXi uses the same offline `.deb` machinery as Proxmox (but for `open-vm-tools` instead of `qemu-guest-agent`, since neither package is on the Debian 13 DVD-1).
- New Windows 11 build on ESXi adds a VMware Tools ISO mount alongside the Windows install ISO; the autounattend's FirstLogonCommands installs VMware Tools and OpenSSH Server silently.
- New `hypervisors/esxi/scripts/`-style helpers are intentionally not committed — see the "ESXi standalone template caveat" in Known Limitations for the manual conversion workflow.
- Documented hypervisor-specific known limitations (no `MarkAsTemplate` API on standalone ESXi, Ubuntu 26.04 overlay-FS kernel bug on ESXi, Ubuntu Desktop autoinstall broken by upstream snap bug on ESXi).
- **The `proxmox/` directory is unchanged from V3.4** — the Proxmox V3.4 ticket merged earlier remains stable and the new ESXi work cannot regress Proxmox builds.

✔ What changed in V3.4?

- Added **offline / air-gapped build support**: Debian, Ubuntu and Windows 11 templates can be built on a Packer host with no internet access.
- Linux: `qemu-guest-agent` and its dependencies are shipped as local `.deb` files, served over Packer's built-in HTTP server and installed during the build.
- Windows 11: OpenSSH Server is installed from a bundled MSI instead of the online Features on Demand.
- Upgraded the Ubuntu profiles from 24.04 to 26.04 (resolute).

✔ What changed in V3.3?

- Added full support for **Windows 11** using `autounattend.xml`.
- Created an independent `hypervisors/proxmox/windows/` directory to separate Linux and Windows build contexts.
- Unified remote connections by using **native OpenSSH** on Windows instead of legacy WinRM.
- The templates are strictly separated by OS family to prevent configuration drift.

⚙️ Prerequisites

**Common (both hypervisors):**
- **Packer ≥ 1.11.0**
- SSH key created locally for Packer: `~/.ssh/id_ed25519`
- ISO creation tool (`xorriso` or `mkisofs`) on the Packer host for Windows builds (Packer generates a small CD at build time for `Autounattend.xml` and the OpenSSH MSI)

**For Proxmox builds:**
- **Proxmox VE** (with access to ISO storage & LVM-thin storage)
- API Token for Packer → Proxmox communication
- Ability to SSH from Packer → Proxmox node

**For ESXi builds:**
- **VMware ESXi 8.0 Update 3** or later (the Debian 13 guest OS identifier `debian13_64Guest` was added in 8.0u3; older versions may need a fallback such as `debian12_64Guest`)
- ESXi SSH service enabled (Host → Manage → Services → TSM-SSH → Start) — required by the `vsphere-iso` plugin for ISO upload and VM provisioning
- Username/password for ESXi authentication (standalone ESXi does not issue API tokens — the build passes the password at runtime via `-var "vsphere_password=..."`)
- ISO upload privileges to a VMFS datastore

# 📦 Packer Requirements

This project relies on specific versions of Packer and the relevant hypervisor plugins.
These requirements ensure full compatibility with the features used in this builder (HTTP provisioning, dynamic templates, plugin schema, etc.).

# 🔧 Required Packer Version

Packer 1.11.0 or higher is required:

```hcl
packer {
  required_version = ">= 1.11.0"
}
```

This version introduces internal improvements and plugin-handling changes that are needed for this project to run correctly.

# 🔌 Required Hypervisor Plugins

The relevant builder plugin must be explicitly declared in `plugins.pkr.hcl` so Packer can automatically download and validate it.

**Proxmox** (`proxmox/{linux,windows}/plugins.pkr.hcl`):

```hcl
required_plugins {
  proxmox = {
    source  = "github.com/hashicorp/proxmox"
    version = ">= 1.1.0"
  }
}
```

**ESXi** (`esxi/{linux,windows}/plugins.pkr.hcl`):

```hcl
required_plugins {
  vsphere = {
    source  = "github.com/hashicorp/vsphere"
    version = ">= 1.0.0"
  }
}
```

# 📝 Summary

| Component              | Requirement | Reason                                                  |
| ---------------------- | ----------- | ------------------------------------------------------- |
| **Packer**             | ≥ 1.11.0    | Needed for plugin system and modern HCL behavior        |
| **Proxmox plugin**     | ≥ 1.1.0     | Ensures compatibility with Proxmox ISO builder features |
| **vSphere plugin**     | ≥ 1.0.0     | Ensures compatibility with ESXi ISO builder features    |
| **No manual download** | ✔️          | Packer fetches the plugin automatically at runtime      |

If these requirements are not met, Packer may fail to run or produce an invalid VM template.

# 🌐 Offline / Air-Gapped Setup

If the build machine has no internet access, the relevant plugin (Proxmox or vSphere) cannot be downloaded by `packer init` at runtime. It must be pre-fetched on a machine with internet and transferred to the offline machine. The procedure is identical for both plugins — just adapt the source name.

## Option 1 — Transfer the plugin cache (recommended)

On a machine **with internet access**, from any directory containing a `plugins.pkr.hcl`:

```bash
# Proxmox
cd hypervisors/proxmox/linux
packer init .

# ESXi
cd hypervisors/esxi/linux
packer init .
```

Packer downloads the plugin into its local cache:

- Linux/macOS: `~/.config/packer/plugins/github.com/hashicorp/<proxmox|vsphere>/`
- Windows: `%APPDATA%\packer\plugins\github.com\hashicorp\<proxmox|vsphere>\`

Copy that directory to the **offline machine** at the same path. Once in place, `packer init` on the offline machine will reuse the cached plugin and will not attempt any network call.

## Option 2 — Install the plugin from a downloaded binary

Download the matching binary from the GitHub releases page ([packer-plugin-proxmox](https://github.com/hashicorp/packer-plugin-proxmox/releases) or [packer-plugin-vsphere](https://github.com/hashicorp/packer-plugin-vsphere/releases)), transfer it to the offline machine, then install it locally:

```bash
# Proxmox
packer plugins install --path /path/to/packer-plugin-proxmox_vX.Y.Z github.com/hashicorp/proxmox

# ESXi
packer plugins install --path /path/to/packer-plugin-vsphere_vX.Y.Z github.com/hashicorp/vsphere
```

This avoids needing a second machine with Packer installed, but requires a manual version check.

> 💡 To make plugin resolution fully deterministic in an offline context, consider pinning the version exactly in `plugins.pkr.hcl` (e.g. `version = "1.1.0"` instead of `>= 1.1.0`).

## Debian build

The Debian build installs guest tools (`qemu-guest-agent` on Proxmox, `open-vm-tools` on ESXi) and their runtime dependencies from a local folder, served base64-encoded over Packer's built-in HTTP server during the install. The preseed's `late_command` downloads them into the VM and installs them with `dpkg -i` before the first reboot, so the guest tools are running when Packer queries the VM's IP.

### ISO

Both the netinst and the full DVD ISO work. Set `iso_file` in the appropriate `profiles/os/debian_13.pkrvars.hcl` file and upload the ISO to the relevant storage (Proxmox storage pool, or ESXi VMFS datastore under `iso/`).

### Local `.deb` packages

The `.deb` files live in `hypervisors/proxmox/linux/offline/debian/debs/` (for Proxmox) or `hypervisors/esxi/linux/offline/debian/debs/` (for ESXi). The binaries themselves are not committed (each folder is kept in git via a `.gitignore` that excludes `*.deb`). The folder must contain the required guest-tools package **and all its runtime dependencies that are not on a fresh Debian 13 base install** — `dpkg -i` does not resolve missing dependencies from a remote source, so every required `.deb` must be present locally.

**For Proxmox (qemu-guest-agent on Debian 13 / trixie)** — 8 packages total. Populate the folder on a Debian 13 machine with internet access:

```bash
sudo apt-get clean
sudo apt-get install -d -y --reinstall \
    qemu-guest-agent \
    libatomic1 libglib2.0-0t64 libglib2.0-data \
    libnuma1 liburing2 shared-mime-info xdg-user-dirs
sudo cp /var/cache/apt/archives/*.deb /path/to/hypervisors/proxmox/linux/offline/debian/debs/
```

**For ESXi (open-vm-tools on Debian 13 / trixie)** — same pattern, with `open-vm-tools` as the target package:

```bash
sudo apt-get clean
sudo apt-get install -d -y --reinstall open-vm-tools
sudo cp /var/cache/apt/archives/*.deb /path/to/hypervisors/esxi/linux/offline/debian/debs/
```

- `apt-get clean` empties the cache so you only grab what you asked for.
- `apt-get install -d --reinstall` with the full list forces re-download of every `.deb`, even those already installed on the source machine.

The `.deb` files must be generated on the same Debian release (Debian 13) as the target VM. If the dependency list changes in a future Debian release, update the package list accordingly.

## Ubuntu build

The Ubuntu Server build on Proxmox uses Ubuntu 26.04 (resolute) and installs `qemu-guest-agent` via the same offline `.deb` machinery as Debian. See `hypervisors/proxmox/linux/offline/ubuntu/debs/` and the original V3.4 instructions below.

The Ubuntu Server build on ESXi uses **Ubuntu 24.04 LTS (noble)** because Ubuntu 26.04 has a reproducible overlay-FS kernel bug during Subiquity's curtin extract phase on ESXi (see Known Limitations). The Ubuntu live-server 24.04 ISO ships `open-vm-tools` as a package in its repositories, so the autoinstall `packages:` list installs it directly — **no offline `.deb` machinery is required for Ubuntu on ESXi**.

### ISO

- **Proxmox:** Both the Ubuntu 26.04 server ISO and the Ubuntu 26.04 desktop ISO work. Set `iso_file` in `hypervisors/proxmox/profiles/os/ubuntu_26_04_server.pkrvars.hcl` (or `ubuntu_26_04_desktop.pkrvars.hcl`) and upload the ISO to your Proxmox storage.
- **ESXi:** Use the Ubuntu 24.04 live-server ISO. Set `iso_file` in `hypervisors/esxi/profiles/os/ubuntu_24_04_server.pkrvars.hcl` and upload to your ESXi datastore.

### Local `.deb` packages (Proxmox only)

The `.deb` files for Ubuntu on Proxmox live in `hypervisors/proxmox/linux/offline/ubuntu/debs/`. The most reliable way to get the exact dependency list for Ubuntu 26.04 is to use a minimal `debootstrap` chroot on an Ubuntu machine with internet access:

```bash
sudo apt-get install -y debootstrap
sudo debootstrap --variant=minbase --components=main,universe resolute /tmp/resolute-chroot http://archive.ubuntu.com/ubuntu/
# Empty the cache filled by debootstrap so only qga-related .debs remain after the next step.
sudo chroot /tmp/resolute-chroot apt-get clean
sudo chroot /tmp/resolute-chroot apt-get update
sudo chroot /tmp/resolute-chroot apt-get install -d -y --no-install-recommends qemu-guest-agent
sudo cp /tmp/resolute-chroot/var/cache/apt/archives/*.deb /path/to/hypervisors/proxmox/linux/offline/ubuntu/debs/
```

This downloads `qemu-guest-agent` and the exact set of dependencies a fresh Ubuntu 26.04 install would need.

## Windows build

The Windows 11 build installs OpenSSH Server from a local MSI instead of fetching it as a Feature on Demand from Windows Update, so the build runs without internet access.

> ⚠️ The Windows build generates CD images at build time (for the `Autounattend.xml` answer file and the OpenSSH MSI). The Packer host therefore needs an ISO creation tool — `xorriso` (or `mkisofs`). Install it on the build machine; in an offline environment, transfer the package the same way as the Packer plugin.

### OpenSSH Server MSI

OpenSSH Server is not pre-staged in the Windows 11 image (`Get-WindowsCapability -Online -Name OpenSSH.Server*` reports `NotPresent`), so `Add-WindowsCapability -Online` would download it from the Windows Update / Features on Demand CDN. The build bundles the Win32-OpenSSH MSI instead.

Download the latest `OpenSSH-Win64` MSI from the [Win32-OpenSSH releases](https://github.com/PowerShell/Win32-OpenSSH/releases), rename it to `OpenSSH-Win64.msi`, and place it in:

```
hypervisors/proxmox/windows/offline/      ← for Proxmox builds
hypervisors/esxi/windows/offline/         ← for ESXi builds
```

The MSI itself is not committed (the folder is kept in git via a `.gitignore` that excludes `*.msi`). At build time, Packer bundles it onto a CD; the autounattend's `FirstLogonCommands` install it with `msiexec /i ... /quiet`, then configure and start the `sshd` service.

### VMware Tools ISO (ESXi only)

The ESXi Windows 11 build additionally mounts the VMware Tools ISO as a second CD-ROM via `iso_paths`. The autounattend's `FirstLogonCommands` Order 3 locates the right CD by looking for `VMwareToolsUpgrader.exe` (unique to the Tools ISO) and then runs `setup.exe /S /v"/qn REBOOT=ReallySuppress"` directly from `cmd` (not via PowerShell, to avoid quote escaping issues).

The simplest way to obtain the Tools ISO is to copy it from the ESXi host itself (ESXi bundles a copy under `/vmimages/tools-isoimages/windows.iso`):

```bash
ssh root@<ESXi-host>
cp /vmimages/tools-isoimages/windows.iso /vmfs/volumes/<datastore>/iso/VMware-tools-windows.iso
```

Then set `vmware_tools_iso_file = "iso/VMware-tools-windows.iso"` in `hypervisors/esxi/profiles/os/windows_11.pkrvars.hcl` (already the default).

> 📌 Note on VMware Tools ISO structure: VMware Tools 12.x (shipped with ESXi 8.0u3+) only includes a single architecture-agnostic `setup.exe` at the ISO root — there is no separate `setup64.exe`. Older versions had both. The autounattend command in this repository targets the 12.x layout.

---

## 🧩 Step 1a — Proxmox Setup

> 💡 **Tip (GUI users):**
> All of this can also be done directly from the Proxmox web interface.
> - Upload the ISO via **Datacenter → Storage → ISO Images**
> - Create API tokens via **Datacenter → Permissions → API Tokens**
> - Check storage names and network bridges directly in the GUI
>
> The guide shows CLI commands because they are reproducible in automation/CI,
> but GUI users can safely follow the same steps visually.

### 1a.1 Create Packer user & permissions

Run on your Proxmox node (as root):

```bash
pveum user add packer@pam
pveum aclmod / -user packer@pam -role PVEVMAdmin
pveum aclmod /storage/local -user packer@pam -role PVEDatastoreAdmin
pveum aclmod /storage/local-lvm -user packer@pam -role PVEDatastoreAdmin
```

### 1a.2 Create an API Token

```bash
pveum user token add packer@pam ci --privsep 0
```

Output:
- 📦 Token ID → `packer@pam!ci`
- Token Secret → used in `hypervisors/proxmox/profiles/site/proxmox.pkrvars.hcl`

## 🧩 Step 1b — ESXi Setup

> 💡 **Tip (GUI users):**
> All of this can also be done from the ESXi web interface.
> - Enable SSH via **Host → Manage → Services → TSM-SSH → Start**
> - Upload ISOs via **Storage → datastore → Browse → iso → Upload**
> - Check datastore names and portgroups directly in the GUI

### 1b.1 Enable SSH on the ESXi host

The `vsphere-iso` plugin needs SSH access to the ESXi host to upload ISOs, monitor the build, and clean up. From the ESXi UI: **Host → Manage → Services → TSM-SSH → Start**.

### 1b.2 Identify the host's inventory name

Standalone ESXi distinguishes between:
- the **API endpoint** (the URL/IP you connect to — set as `vsphere_url`), and
- the **host's inventory name** (the hostname as it appears in vSphere inventory — set as `vsphere_host`).

On a default installation, the inventory name is usually `localhost.localdomain`. To verify, SSH into the host and run:

```bash
hostname
```

Use the returned value in `hypervisors/esxi/profiles/site/esxi.pkrvars.hcl` as `vsphere_host`.

### 1b.3 Identify the datastore and portgroup names

From the ESXi UI:
- **Storage → datastores** — note the name (e.g., `datastore1`)
- **Networking → Port groups** — note the portgroup name (e.g., `VM Network`)

These go in `hypervisors/esxi/profiles/site/esxi.pkrvars.hcl` as `datastore` and `network`.

### 1b.4 No API tokens

Standalone ESXi does not issue API tokens. The build uses username/password authentication. Store the username in `esxi.pkrvars.hcl` and pass the password at build time via `-var "vsphere_password=..."`.

## 🌐 Step 2 — SSH Connectivity (Packer → Hypervisor)

On your Packer machine, generate an SSH key pair (if you don't already have one):

```bash
ssh-keygen -t ed25519 -C "packer@builder"
```

**For Proxmox:** Copy your public key to the Proxmox node:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<PROXMOX_NODE>
ssh root@<PROXMOX_NODE>    # verify
```

**For ESXi:** ESXi standalone uses password-based SSH (the `vsphere-iso` plugin handles its own SSH session via the API password). You do not need to deploy a personal SSH key on the ESXi host for the build to work — but the SSH service itself must be running (see Step 1b.1).

✅ If you are logged in without being asked for a password, SSH key authentication is correctly configured.

Note:
- `<PROXMOX_NODE>` refers to the actual Proxmox node name or IP address as shown in the Proxmox UI (e.g. `pve01`, `192.168.1.10`).
- In a single-node Proxmox setup, host and node refer to the same machine.
- If DNS resolution is not available or unreliable, using the IP address is recommended.

## 🧱 Step 3 — Profile Files

**Proxmox:**
- Site (Proxmox API) : `hypervisors/proxmox/profiles/site/proxmox.pkrvars.hcl`
- OS (Debian / Ubuntu / Windows) : `hypervisors/proxmox/profiles/os/*.pkrvars.hcl`
- Flavor (hardware preset) : `hypervisors/proxmox/profiles/flavors/*.pkrvars.hcl`

**ESXi:**
- Site (ESXi host) : `hypervisors/esxi/profiles/site/esxi.pkrvars.hcl`
- OS (Debian / Ubuntu / Windows) : `hypervisors/esxi/profiles/os/*.pkrvars.hcl`
- Flavor (hardware preset) : `hypervisors/esxi/profiles/flavors/*.pkrvars.hcl`

The Proxmox and ESXi flavor files are identical in structure (`cpus`, `sockets`, `memory`, `disk_gb`) so you can copy your tested hardware presets across hypervisors without changes.

## 🧠 Step 4 — Required Build Variables

All account variables must be passed at build time (none stored in files):

**Proxmox builds:**

| Variable          | Description                            | Required   |
| ----------------- | -------------------------------------- | ---------- |
| `template_id`     | Proxmox VMID for the template (≥ 1000) | ✅         |
| `template_name`   | Hostname / template name               | ✅         |
| `root_password`   | Temporary root password (Linux only)   | ✅ (Linux) |
| `admin_password`  | Temporary admin password (Windows only)| ✅ (Win)   |
| `root_ssh_pubkey` | SSH key to inject into root (Linux)    | ✅ (Linux) |
| `user_username`   | Standard user name                     | ✅         |
| `user_password`   | Standard user password                 | ✅         |

**ESXi builds:**

| Variable           | Description                                      | Required   |
| ------------------ | ------------------------------------------------ | ---------- |
| `vsphere_password` | ESXi root password (passed at build time)        | ✅         |
| `template_name`    | Hostname / template name (≤ 15 chars on Windows) | ✅         |
| `root_password`    | Temporary root password (Linux only)             | ✅ (Linux) |
| `admin_password`   | Temporary admin password (Windows only)          | ✅ (Win)   |
| `root_ssh_pubkey`  | SSH key to inject into root (Linux)              | ✅ (Linux) |
| `user_username`    | Standard user name                               | ✅         |
| `user_password`    | Standard user password                           | ✅         |

Note for ESXi: there is no `template_id` (vSphere identifies VMs by name, not VMID).

## 🧾 Step 5 — Validate and Build (Proxmox)

Depending on the OS you want to build, go into the appropriate directory:

```bash
# For Linux builds (Debian, Ubuntu)
cd hypervisors/proxmox/linux

# For Windows builds
cd hypervisors/proxmox/windows
```

### 5.1 Initialize Packer plugins (first run or after plugin updates)

```bash
packer init .
```

### 5.2 Format your configuration

```bash
packer fmt .
```

> ℹ️ Note: `packer fmt` only formats HCL files for readability and consistency.
> It does **not** validate the configuration logic, variable definitions, or build correctness — this is done separately by `packer validate`.

### 5.3 Validate (Debian example)

```bash
packer validate \
  -only="debian.*" \
  -var-file=../profiles/site/proxmox.pkrvars.hcl \
  -var-file=../profiles/os/debian_13.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_id=1001" \
  -var "template_name=tpl-debian13-ci" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  .
```

### 5.4 Build the Debian template

This command runs the full build pipeline:
- Starts the Proxmox VM
- Mounts the Debian ISO
- Loads the dynamic preseed served by Packer
- Performs an unattended installation
- Configures SSH, keys, and QEMU Guest Agent
- Converts the VM into a Proxmox template automatically

```bash
PACKER_LOG=1 packer build \
  -only="debian.*" \
  -var-file=../profiles/site/proxmox.pkrvars.hcl \
  -var-file=../profiles/os/debian_13.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_id=1001" \
  -var "template_name=tpl-debian13-ci" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  .
```

### 5.5 Validate and Build Ubuntu 26.04 Server

```bash
PACKER_LOG=1 packer build \
  -only="ubuntu.*" \
  -var-file=../profiles/site/proxmox.pkrvars.hcl \
  -var-file=../profiles/os/ubuntu_26_04_server.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_id=1002" \
  -var "template_name=tpl-ubuntu2604-ci" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  .
```

### 5.6 Validate and Build Ubuntu 26.04 Desktop

Same as Server, with `ubuntu_26_04_desktop.pkrvars.hcl` and a different `template_id`/`template_name`.

### 5.7 Validate and Build Windows 11

Ensure you are in the `hypervisors/proxmox/windows` directory.

```bash
PACKER_LOG=1 packer build \
  -only="windows_11.*" \
  -var-file=../profiles/site/proxmox.pkrvars.hcl \
  -var-file=../profiles/os/windows_11.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_id=1004" \
  -var "template_name=tpl-windows11-ci" \
  -var "admin_password=TempRoot123" \
  -var "user_username=user" \
  -var "user_password=user" \
  .
```

## 🧾 Step 5bis — Validate and Build (ESXi)

The ESXi build directory uses `hypervisors/esxi/linux/` (Debian and Ubuntu Server) or `hypervisors/esxi/windows/` (Windows 11). Note that **the ESXi build command points the path argument at the directory itself** (e.g. `hypervisors/esxi/linux/`) and is typically run from the repository root, unlike the Proxmox examples which `cd` into the directory.

### 5bis.1 Initialize Packer plugins

```bash
packer init hypervisors/esxi/linux/
packer init hypervisors/esxi/windows/
```

### 5bis.2 Validate and Build Debian 13 (ESXi)

```bash
PACKER_LOG=1 packer build \
  -var-file=hypervisors/esxi/profiles/site/esxi.pkrvars.hcl \
  -var-file=hypervisors/esxi/profiles/os/debian_13.pkrvars.hcl \
  -var-file=hypervisors/esxi/profiles/flavors/medium.pkrvars.hcl \
  -var "vsphere_password=ESXiPassword!" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  -var "template_name=tpl-debian13-ci" \
  hypervisors/esxi/linux/
```

### 5bis.3 Validate and Build Ubuntu 24.04 Server (ESXi)

```bash
PACKER_LOG=1 packer build \
  -var-file=hypervisors/esxi/profiles/site/esxi.pkrvars.hcl \
  -var-file=hypervisors/esxi/profiles/os/ubuntu_24_04_server.pkrvars.hcl \
  -var-file=hypervisors/esxi/profiles/flavors/medium.pkrvars.hcl \
  -var "vsphere_password=ESXiPassword!" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  -var "template_name=tpl-ubuntu2404-ci" \
  hypervisors/esxi/linux/
```

### 5bis.4 Validate and Build Windows 11 (ESXi)

```bash
PACKER_LOG=1 packer build \
  -var-file=hypervisors/esxi/profiles/site/esxi.pkrvars.hcl \
  -var-file=hypervisors/esxi/profiles/os/windows_11.pkrvars.hcl \
  -var-file=hypervisors/esxi/profiles/flavors/medium.pkrvars.hcl \
  -var "vsphere_password=ESXiPassword!" \
  -var "admin_password=TempAdmin123" \
  -var "user_username=user" \
  -var "user_password=user" \
  -var "template_name=tpl-win11-ci" \
  hypervisors/esxi/windows/
```

📜 Notes:
- **PACKER_LOG=1** enables verbose output for troubleshooting.
- You can replace **medium.pkrvars.hcl** with any flavor file (**light**, **hard**, **extreme**) depending on your needs.
- Ensure the specified **template_name** is unique within your ESXi inventory and ≤ 15 characters on Windows (hostname limit).

## ⚙️ Step 6 — How It Works

- **For Debian:** The legacy installer requires a standard Preseed file. Packer renders the dynamic `preseed.pkrtpl.hcl` in memory and serves it.
- **For Ubuntu:** Canonical's modern Subiquity installer requires Cloud-init for Autoinstall. Packer renders the strict YAML format `user-data.pkrtpl.hcl` (along with an empty `meta-data` file) in memory.
- **For Windows:** The installer uses a dynamic answer file (`autounattend.pkrtpl.hcl`). Packer injects registry keys to bypass Windows 11 TPM/SecureBoot checks for VMs, configures the disk, and bypasses OOBE.
- The OS installer retrieves these configuration files via Packer's temporary HTTP server (e.g., `url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/...`).
- **Post-Install Provisioning & Security:**
    - On **Linux**, Packer temporarily connects via SSH using the clear-text root password. On **Windows**, the answer file installs native OpenSSH and Packer connects via SSH using the clear-text administrator password.
    - On **Linux**, the provided **SSH public key is deployed** for the root user.
    - On **Linux**, **password login for root is then permanently disabled** (via SSH drop-in configs). The final Linux template strictly allows SSH key-only access for root. On **Windows**, password authentication remains enabled for both the administrator and the standard user, allowing flexible remote administration.
    - Guest tools are installed and started: QEMU Guest Agent on Proxmox, open-vm-tools (Linux) or VMware Tools (Windows) on ESXi.
- On Proxmox, the VM is automatically converted into a reusable, secure Proxmox template. On ESXi standalone, the VM is left powered off — see Known Limitations for the conversion caveat and recommended workflow.

## 🧩 Step 7 — Example Output

**Proxmox:**

```yaml
==> debian.proxmox-iso.debian: Waiting for SSH to become available...
==> debian.proxmox-iso.debian: Connected to SSH!
==> debian.proxmox-iso.debian: Provisioning with shell script...
==> debian.proxmox-iso.debian: Converting VM to template
--> debian.proxmox-iso.debian: A template was created: 1001 (tpl-debian13-ci)
```

**ESXi:**

```yaml
==> debian.vsphere-iso.debian: Waiting for IP...
==> debian.vsphere-iso.debian: IP address: 192.168.10.125
==> debian.vsphere-iso.debian: Waiting for SSH to become available...
==> debian.vsphere-iso.debian: Connected to SSH!
==> debian.vsphere-iso.debian: Provisioning with shell script...
==> debian.vsphere-iso.debian: Running shutdown command...
==> debian.vsphere-iso.debian: Deleting floppy drives...
==> debian.vsphere-iso.debian: Ejecting CD-ROM media...
==> debian.vsphere-iso.debian: Clearing boot order...
--> debian.vsphere-iso.debian: tpl-debian13-ci
```

---

## ⚠️ Known Limitations on ESXi

The Proxmox builds in this repository are fully automated end-to-end. The ESXi builds work, but have a few caveats that are out of our control (upstream bugs or hypervisor design choices). Each item below is documented inline in the relevant `.pkr.hcl` / `.pkrvars.hcl` file.

### 1. No automatic conversion to template on standalone ESXi

Standalone ESXi (no vCenter) does not expose the `VirtualMachine.MarkAsTemplate()` API used by `convert_to_template = true`. Attempting to use it fails with `ServerFaultCode: The operation is not supported on the object.` Furthermore, the ESXi web UI in version 8.0+ has removed the "Convert to Template" right-click action that older versions exposed.

`convert_to_template` is therefore set to `false` in all three ESXi source blocks (`debian.pkr.hcl`, `ubuntu.pkr.hcl`, `windows_11.pkr.hcl`). The build leaves a powered-off VM that you can use directly as the "golden image".

**To clone from the powered-off VM**: use the ESXi UI's `Actions → Export` to download an OVF/OVA bundle, then re-import via `Create / Register VM → Deploy a virtual machine from an OVF or OVA file`. Slower than a vCenter clone but reliable and entirely UI-driven.

Setting `convert_to_template = true` in a vCenter-managed setup will Just Work — the option is preserved as a documented switch in the source blocks.

### 2. Ubuntu 26.04 LTS overlay-FS bug on ESXi

Ubuntu 26.04 LTS ships a kernel with a reproducible bug in the overlay filesystem driver (`ovl_iterate_merged`). On ESXi, Subiquity's curtin extract phase reliably triggers a kernel oops when rsync iterates the live-server overlay during the install image copy. The same Ubuntu 26.04 build works on Proxmox (different hardware emulation), so the bug appears to be triggered by an interaction with VMware's virtual hardware.

**Mitigation in this repo**: `hypervisors/esxi/profiles/os/ubuntu_24_04_server.pkrvars.hcl` points to Ubuntu 24.04 LTS (noble) ISOs instead of 26.04. Once Ubuntu ships a kernel update that fixes the overlay bug, a new `ubuntu_26_04_server.pkrvars.hcl` profile can be added without disrupting the 24.04 profile.

### 3. Ubuntu Desktop autoinstall broken on ESXi

The `ubuntu-desktop-bootstrap` snap (which wraps Subiquity for the Desktop edition) has a reproducible `sfdisk` failure during the partitioning step on ESXi:

```
/dev/sda1: Sector 2048 already used.
Failed to add #1 partition: Numerical result out of range
```

This triggers regardless of BIOS/UEFI firmware, disk controller choice (`lsilogic-sas` or `pvscsi`), or memory configuration. The Ubuntu Server edition installs fine on the same ESXi host with the same `user-data`, and the same Desktop build works on Proxmox — so the bug is in the snap itself. Needs an upstream fix from Canonical.

**Status**: `hypervisors/esxi/profiles/os/ubuntu_24_04_desktop.pkrvars.hcl` is shipped with a `KNOWN BROKEN ON ESXi` header comment and is not used in routine builds. Retry once a newer `ubuntu-desktop-bootstrap` snap ships.

### 4. VMware Tools ISO structure (12.x vs older)

VMware Tools 12.x (shipped with ESXi 8.0u3+) consolidates both the 32-bit and 64-bit installers into a single architecture-agnostic `setup.exe` at the ISO root — there is no separate `setup64.exe`. The Windows autounattend in this repository targets the 12.x layout: it identifies the VMware Tools CD by the unique presence of `VMwareToolsUpgrader.exe`, then runs `setup.exe /S /v"/qn REBOOT=ReallySuppress"` from `cmd` (the official VMware silent install syntax).

If you are on an older ESXi/VMware Tools combination that still ships `setup64.exe`, adapt the marker file and executable name in Order 3 of `hypervisors/esxi/windows/http/windows_11/autounattend.pkrtpl.hcl`.

### 5. `CPUs` parameter in vsphere-iso v2.x

Despite what the plugin documentation suggests, the `CPUs` parameter of `vsphere-iso` v2.x maps directly to vSphere's `numCPUs` field (total vCPUs), not to the number of CPU sockets. This repository computes `CPUs = var.sockets * var.cpus` explicitly in all three ESXi source blocks to produce the intended total vCPU count from the flavor profile's `sockets` and `cpus` values.

---

🔐 Security Notes

- Never commit secrets (API tokens, passwords, ESXi passwords, or private SSH keys).
- Rotate API tokens, ESXi passwords, and SSH keys regularly.
- Restrict Proxmox API users to minimal roles (principle of least privilege).
- On ESXi, prefer a dedicated service account over the root user if your environment permits it.
- Root access via password is disabled after provisioning (Linux).
- Preseed, Kickstart, autounattend, and cloud-init configurations are rendered in memory and never written to disk.

## 🚀 Next Steps: Using Your Template

Once the template is created, you can deploy VMs from it using several methods depending on your workflow and hypervisor.

### On Proxmox

#### 🖥️ Option 1 — Proxmox Web Interface (recommended for beginners)
1. Go to **Datacenter → your-node → Template**
2. Right-click the template → **Clone**
3. Choose: Clone mode (Linked Clone or Full Clone), Target Storage, VM Name
4. Validate → VM is ready.

#### 🛠️ Option 2 — Proxmox CLI

```bash
qm clone 1001 120 --name debian-ci --full 1 --storage local-lvm
```

#### 🤖 Option 3 — Ansible

Using the module `community.general.proxmox_kvm`, you can automate VM creation directly from playbooks.

#### 🌍 Option 4 — Terraform

Using the widely adopted Proxmox provider `telmate/proxmox`, Terraform can manage templates, VMs, disks, networking, and lifecycle.

#### 🔌 Option 5 — Proxmox API

Using raw API calls: `POST /nodes/{node}/qemu/{vmid}/clone`. Ideal for advanced CI/CD integrations.

### On ESXi standalone

Since standalone ESXi has no template concept exposed by the UI (see Known Limitations), the recommended workflow is:

#### 🖥️ Option 1 — OVF export / import (UI-native, recommended)
1. Right-click the powered-off VM left by the build → **Actions → Export** (or "Export With Images")
2. Download the generated `.ovf` and `.vmdk` files
3. To create a new VM from this OVF: **Create / Register VM → Deploy a virtual machine from an OVF or OVA file**, upload the files, give the new VM a name. Repeat as often as needed.

#### 🛠️ Option 2 — VMFS file-level copy (advanced)

For faster duplication without going through OVF, SSH into the ESXi host and copy the VM's directory:

```bash
ssh root@<ESXi-host>
cp -r /vmfs/volumes/<datastore>/tpl-debian13-ci /vmfs/volumes/<datastore>/new-vm
# Edit the .vmx to update vm name and uuid, then register
vim-cmd solo/registervm /vmfs/volumes/<datastore>/new-vm/new-vm.vmx
```

#### 🌍 Option 3 — Terraform (vSphere provider)

Using `hashicorp/vsphere`, you can use the powered-off VM as a clone source. Note that the standalone-ESXi clone operation has limitations compared to vCenter, but it does work for simple full-clone workflows.

-> With any of these methods, your pre-configured templates become the base for consistent, reproducible VM deployments.

✅ You're done!

You now have a fully automated, dynamic, and hardened multi-OS (Linux & Windows), multi-hypervisor (Proxmox & ESXi) template generation pipeline.
