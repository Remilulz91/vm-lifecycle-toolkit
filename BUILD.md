# 📖 Build Guide — VM Lifecycle Toolkit

This document contains the detailed step-by-step instructions for building VM templates with this project (hypervisor setup, offline plugin cache, Packer validate / build commands, worked examples).

For an overview of the project (features, repository layout, known limitations, security notes, deployment options), see [README.md](README.md).

---

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
pveum aclmod /sdn/zones/localnetwork -user packer@pam -role PVESDNUser
```

> 📌 **Note on `PVESDNUser` (Proxmox VE 8+)**: Starting with Proxmox VE 8, traditional network bridges (`vmbr*`) are managed under the SDN (Software-Defined Networking) framework. Attaching a VM to a bridge now requires the `SDN.Use` permission (granted via the `PVESDNUser` role) on `/sdn/zones/<zone>/<bridge>`. The default auto-created zone that wraps traditional bridges is `localnetwork`. Without this grant, the Packer build fails during VM creation with `403 Permission check failed (/sdn/zones/localnetwork/vmbr0, SDN.Use)`. On older Proxmox VE 7.x, this line can be safely omitted (the SDN check is not enforced).

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

## 🧩 Step 1c — Ansible user on Proxmox (V3.7+)

> 📌 **Required only if you plan to use the Ansible side of the project** (cloning VMs from Packer-built templates — see [ansible/README.md](ansible/README.md)). If you only use Packer to build templates, skip this step.

The Ansible playbooks need a **dedicated service account** on Proxmox with permissions to clone, configure and start VMs. We keep this user distinct from the `packer@pam` user so the two sides of the stack can be audited and revoked independently.

### 1c.1 Create the Ansible user & permissions

Run on your Proxmox node (as root):

```bash
pveum user add ansible@pam
pveum aclmod / -user ansible@pam -role PVEVMAdmin
pveum aclmod /storage/local -user ansible@pam -role PVEDatastoreAdmin
pveum aclmod /storage/local-lvm -user ansible@pam -role PVEDatastoreAdmin
pveum aclmod /sdn/zones/localnetwork -user ansible@pam -role PVESDNUser
```

> Permissions mirror those of the Packer user: `PVEVMAdmin` covers VM lifecycle (clone, config, start/stop), `PVEDatastoreAdmin` covers storage allocation during the clone, and `PVESDNUser` covers network bridge attachment on Proxmox VE 8+ (same requirement as Packer — see note under step 1a.1).

### 1c.2 Create an API token for Ansible

```bash
pveum user token add ansible@pam ci --privsep 0
```

Output:
- 📦 Token ID → `ansible@pam!ci`
- Token Secret → used by Ansible at runtime via the `PROXMOX_API_TOKEN_SECRET` environment variable (or encrypted with `ansible-vault` — see [ansible/README.md](ansible/README.md))

### 1c.3 Install Ansible dependencies on the controller

On the machine that will run `ansible-playbook` (your laptop, a CI runner, etc.):

#### Python dependencies

> ⚠️ **Debian 13 / Ubuntu 24.04 note**: the system package `python3-proxmoxer` ships **version 2.2.0**, which is **too old** for the current `community.proxmox` collection (requires proxmoxer **≥ 2.3**). You cannot rely on `sudo apt install python3-proxmoxer` — you need pip-based install. And `pip install` on the system Python is blocked by PEP 668. **→ Use a venv.**

**Option A — Virtual environment (recommended, cross-distro)**

```bash
cd ansible/
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Remember to `source venv/bin/activate` at the start of every new shell session before running `ansible-playbook`.

**Option B — Break system packages (last resort, Debian/Ubuntu)**

```bash
# Remove the apt-shipped version first (2.2.0, incompatible):
sudo apt remove python3-proxmoxer python3-requests

# Install the pip version system-wide, overriding PEP 668:
pip install --break-system-packages -r requirements.txt
```

#### Ansible collections (into `./collections/`, not system-wide)

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
```

For the detailed usage of the Ansible playbooks (how to describe VMs to clone, how to run the playbook, how to limit to a specific host, how to handle secrets with `ansible-vault`), see [ansible/README.md](ansible/README.md).

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

**QEMU/KVM:**
- Site (local build settings — accelerator, headless, output dir) : `hypervisors/qemu/profiles/site/qemu.pkrvars.hcl`
- OS (Debian / Ubuntu — `iso_url` + `iso_checksum`) : `hypervisors/qemu/profiles/os/*.pkrvars.hcl`
- Flavor (hardware preset) : `hypervisors/qemu/profiles/flavors/*.pkrvars.hcl`

The three hypervisors share the same flavor file schema (`cpus`, `sockets`, `memory`, `disk_gb`) so you can copy tested hardware presets across them without changes.

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

**QEMU/KVM builds:**

| Variable           | Description                                            | Required   |
| ------------------ | ------------------------------------------------------ | ---------- |
| `template_name`    | Hostname / `.qcow2` filename (`<template_name>.qcow2`) | ✅         |
| `root_password`    | Temporary root password (Linux only)                   | ✅ (Linux) |
| `root_ssh_pubkey`  | SSH key to inject into root (Linux)                    | ✅ (Linux) |
| `user_username`    | Standard user name                                     | ✅         |
| `user_password`    | Standard user password                                 | ✅         |

Note for QEMU/KVM: no remote hypervisor credentials — the build runs locally on the Packer host. The ISO location + checksum come from the OS profile (`iso_url` + `iso_checksum`), not from `-var`.

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

## 🧾 Step 5ter — Validate and Build (QEMU/KVM)

The QEMU/KVM track builds **locally** on the host that runs Packer (no remote hypervisor). The artefact is a `.qcow2` file you later import into libvirt with `virt-install --import` — administrable visually through Cockpit (`cockpit-machines`).

### 5ter.0 Prerequisites on the Packer host

The host that runs Packer **is** the KVM host.

```bash
# Core bits
sudo apt install packer qemu-system-x86 qemu-utils ovmf

# Enable /dev/kvm access for your user
sudo adduser "$USER" kvm
sudo adduser "$USER" libvirt   # for virt-install later
# → log out / back in to pick up the new groups
```

Check KVM is really available:

```bash
ls -l /dev/kvm                                     # exists, rw for the kvm group
which qemu-system-x86_64                           # not empty
egrep -c '(vmx|svm)' /proc/cpuinfo                 # non-zero
```

For visual administration via Cockpit:

```bash
sudo apt install cockpit cockpit-machines libvirt-daemon-system virtinst
sudo systemctl enable --now cockpit.socket
# → http://<host>:9090
```

### 5ter.1 Download the installer ISO

Download the ISO once into a cache the Packer host can read, then update the matching OS profile with its SHA-256:

```bash
sudo mkdir -p /var/cache/isos
sudo curl -L \
  https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-13.5.0-amd64-DVD-1.iso \
  -o /var/cache/isos/debian-13.5.0-amd64-DVD-1.iso

sha256sum /var/cache/isos/debian-13.5.0-amd64-DVD-1.iso
# → paste the hash into hypervisors/qemu/profiles/os/debian_13.pkrvars.hcl (iso_checksum)
```

Same shape for Ubuntu Server 26.04 (`iso_url` + `iso_checksum` in `profiles/os/ubuntu_26_04_server.pkrvars.hcl`).

### 5ter.2 Initialize Packer plugins

```bash
cd hypervisors/qemu/linux
packer init .
```

### 5ter.3 Validate and Build Debian 13 (QEMU)

```bash
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
```

Artefact: `hypervisors/qemu/linux/output-tpl-debian13-qemu/tpl-debian13-qemu.qcow2`.

### 5ter.4 Validate and Build Ubuntu 26.04 Server (QEMU)

```bash
PACKER_LOG=1 packer build \
  -only="ubuntu.*" \
  -var-file=../profiles/site/qemu.pkrvars.hcl \
  -var-file=../profiles/os/ubuntu_26_04_server.pkrvars.hcl \
  -var-file=../profiles/flavors/medium.pkrvars.hcl \
  -var "template_name=tpl-ubuntu2604-qemu" \
  -var "root_password=TempRoot123" \
  -var "root_ssh_pubkey=$(cat ~/.ssh/id_ed25519.pub)" \
  -var "user_username=user" \
  -var "user_password=user" \
  .
```

📜 Notes:
- Headless by default. To watch the install happen, add `-var "qemu_headless=false"` or connect via VNC — Packer prints the VNC port in its logs.
- `template_name` is used both as the Linux hostname during install and as the `.qcow2` filename.
- Windows 11 on QEMU is not yet supported (needs TPM 2.0 via `swtpm`, OVMF, Secure Boot keys — planned for V3.8.1).

### 5ter.5 Import the `.qcow2` into libvirt / Cockpit

Once Packer is done, register the image as a VM and start it. It appears immediately in Cockpit → Virtual Machines.

```bash
# Move the image into a libvirt storage pool
sudo cp output-tpl-debian13-qemu/tpl-debian13-qemu.qcow2 /var/lib/libvirt/images/
sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/tpl-debian13-qemu.qcow2

# --import = reuse an existing disk, no OS install
sudo virt-install \
  --name tpl-debian13-qemu \
  --memory 4096 --vcpus 2 \
  --disk path=/var/lib/libvirt/images/tpl-debian13-qemu.qcow2,format=qcow2 \
  --os-variant debian13 \
  --network network=default,model=virtio \
  --import \
  --noautoconsole
```

**Example output (QEMU):**

```yaml
==> debian.qemu.debian: Waiting for SSH to become available...
==> debian.qemu.debian: Connected to SSH!
==> debian.qemu.debian: Provisioning with shell script...
==> debian.qemu.debian: Gracefully halting virtual machine...
--> debian.qemu.debian: output-tpl-debian13-qemu/tpl-debian13-qemu.qcow2
```

### 5ter.6 Troubleshooting (QEMU-specific)

- **`exec: "qemu-system-x86_64": executable file not found in $PATH`** — the Packer host doesn't have QEMU installed. Fix: `sudo apt install qemu-system-x86 qemu-utils ovmf` (see 5ter.0).
- **`Could not access KVM kernel module: Permission denied`** — the user doesn't have access to `/dev/kvm`. Fix: `sudo adduser "$USER" kvm` and log out / back in. Verify with `ls -l /dev/kvm`.
- **`Undefined -var variable` on `template_name` / `root_password` / …** — Packer was given a single `.pkr.hcl` file and ignored `variables.pkr.hcl`. **Always pass `.` (the directory) at the end of the command, not a specific file**, and scope with `-only="<build>.*"`. The commands in 5ter.3 and 5ter.4 already do this.
- **`Timeout waiting for SSH`, no output in headless mode** — the Debian installer is stuck on an interactive screen you can't see. The project's `boot_command` already injects `language=en country=FR locale=en_US.UTF-8` + `fb=false` + `debconf/frontend=noninteractive` and the `late_command` is written to tolerate an empty offline debs set, but if you've tweaked anything, re-check. **Visual diagnosis via VNC** (the only reliable way to see the install screen on a remote Packer host):

  ```bash
  # Option A — SSH tunnel (safest, nothing exposed on the network)
  # On your workstation:
  ssh -L 5900:127.0.0.1:5900 user@packer-host
  # In another terminal, launch the build on the Packer host. Packer picks the
  # pinned port 5900 (set in profiles/site/qemu.pkrvars.hcl).
  # Then open vnc://localhost:5900 on your workstation (TigerVNC / Remmina / VNC Viewer).

  # Option B — expose VNC on the Packer host network (less safe, LAN only)
  # Edit profiles/site/qemu.pkrvars.hcl: qemu_vnc_bind_address = "0.0.0.0"
  # Open your firewall for port 5900 if needed, then VNC to <packer-host>:5900.
  ```

  Once connected, you'll see exactly what the installer is doing — a frozen dialog, a disk error, a package-select screen, etc.
- **ISO filename vs profile** — the OS profiles under `hypervisors/qemu/profiles/os/` reference the **DVD-1** ISO (offline-capable: all packages live on the DVD). If you downloaded `netinst` instead, the install will try to reach `deb.debian.org` and may fail on an offline host. Stick to DVD-1 for consistency with the Proxmox / ESXi tracks.

---
