# 🧱 VM Lifecycle Toolkit — Build & Deploy VMs on Proxmox and ESXi

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v3.7-blue.svg)](README.md)
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

# 📁 Repository Layout (V3.7 — Multi-OS, Multi-Hypervisor, Multi-Tool)

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
├─ ansible/                                     ← V3.7: Clone VMs from Packer templates (Proxmox-first)
│  ├─ ansible.cfg                               (Ansible config)
│  ├─ requirements.yml                          (collections: community.general, ansible.posix)
│  ├─ requirements.txt                          (Python: proxmoxer, requests)
│  ├─ inventories/
│  │  └─ proxmox/
│  │     ├─ hosts.yml                           (static inventory — VMs to clone)
│  │     └─ group_vars/all.yml                  (Proxmox API endpoint, user, timeouts)
│  ├─ playbooks/
│  │  └─ clone-from-template.yml                (entry-point playbook)
│  ├─ roles/
│  │  └─ proxmox_clone/                         (role: clone + optional SSH wait)
│  └─ README.md
│
├─ terraform/                                   ← [Planned V3.8+] VM cloning via Terraform
├─ LICENSE
└─ README.md
```

✔ What changed in V3.7?

- **Added Ansible side** of the project — new top-level `ansible/` directory with scaffolding for cloning VMs from Packer-built templates on Proxmox.
- New `proxmox_clone` role (based on `community.general.proxmox_kvm`): clones a template VM, applies optional hardware overrides, starts the clone, and (optionally) waits for SSH on a user-provided IP.
- Static YAML inventory format for describing VMs to clone (`ansible/inventories/proxmox/hosts.yml`). Dynamic inventory planned for V3.7.3.
- Dedicated `ansible@pam` user on Proxmox (parallel to `packer@pam`) with its own API token — setup documented in BUILD.md Step 1c.
- Entry-point playbook: `ansible/playbooks/clone-from-template.yml`.
- Dedicated `ansible/README.md` with install steps, quick-start, secrets handling (env var or `ansible-vault`) and roadmap.
- **Minimal scope on purpose**: V3.7 only clones + starts VMs. Post-clone configuration (base_config, docker_host, webserver, etc.) planned for V3.7.1+. ESXi support planned for V3.7.2 (via `community.vmware` OVF deploy).

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

---

# 📖 Full Build Guide

For the detailed step-by-step build instructions, see **[BUILD.md](BUILD.md)**.

That guide covers:

- Offline / air-gapped plugin cache and `.deb` package preparation
- Proxmox + ESXi host setup (users, tokens, SSH, datastores, portgroups)
- Profile file layout and required build variables
- `packer validate` / `packer build` command examples for each OS × each hypervisor
- Internals: how preseed / autoinstall / autounattend are served and consumed
- Example Packer log output


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

---

## 📜 Copyright & Ownership

This project — **VM Lifecycle Toolkit** — is the exclusive intellectual property of **Rémi Rousselot**.

**Copyright © 2025-2026 Rémi Rousselot. All rights reserved.**

This repository is published publicly on GitHub for **viewing and reference purposes only**. See [LICENSE](LICENSE) for the full terms, which strictly prohibit without prior written permission from the copyright holder:

- Copying, cloning, downloading, or forking the Software for any use beyond brief personal reference while viewing on GitHub.
- Redistributing, republishing, mirroring, or hosting the Software (or any derivative work) in any form on any platform.
- Modifying, adapting, translating, reverse-engineering, or creating derivative works.
- Using the Software in any production, commercial, educational, personal, or non-commercial environment, including building VM templates or integrating with any infrastructure.
- Claiming authorship, ownership, co-authorship, or any form of attribution over the Software or any portion of it.
- Selling, sublicensing, leasing, renting, or otherwise commercially exploiting the Software.

Any usage beyond pure visual inspection on GitHub requires prior written permission from the copyright holder, obtainable via [remi.rousselot91@gmail.com](mailto:remi.rousselot91@gmail.com).

The copyright holder reserves the right to revoke this limited viewing permission at any time, without notice.

---

**Author:** Rémi Rousselot  
**Project:** VM Lifecycle Toolkit  
**Version:** V3.7  
**Contact:** [remi.rousselot91@gmail.com](mailto:remi.rousselot91@gmail.com)
