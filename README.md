# 🧱 VM Lifecycle Toolkit — Build & Deploy VMs on Proxmox and ESXi

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v3.7.7-blue.svg)](README.md)
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
│  │  ├─ clone-from-template.yml                (step 1 Proxmox: clone + start, Proxmox API)
│  │  ├─ deploy-from-ovf.yml                    ← V3.7.5: step 1 ESXi: OVF deploy via community.vmware
│  │  ├─ configure-vm.yml                       ← V3.7.2: step 2 baseline config over SSH (both hypervisors)
│  │  └─ decommission-vm.yml                    ← V3.7.7: destructive teardown (both hypervisors, confirm-gated)
│  ├─ roles/
│  │  ├─ proxmox_clone/                         (role: clone + optional SSH wait)
│  │  ├─ base_config/                           ← V3.7.2: hostname, tz, admin user, SSH hardening
│  │  ├─ docker_host/                           ← V3.7.3: Docker CE + Compose plugin
│  │  ├─ webserver/                             ← V3.7.3: nginx + demo vhost
│  │  ├─ base_config_windows/                   ← V3.7.4: Windows baseline (SSH + PowerShell)
│  │  ├─ esxi_deploy/                           ← V3.7.5: OVF deploy to standalone ESXi
│  │  ├─ proxmox_decommission/                  ← V3.7.7: stop + delete Proxmox VM
│  │  └─ esxi_decommission/                     ← V3.7.7: power-off + delete ESXi VM
│  ├─ scripts/                                  ← V3.7.1: Air-gapped bundle helpers
│  │  ├─ prepare-offline-bundle.sh              (online host: pack collections + wheels)
│  │  └─ install-offline-bundle.sh              (offline host: install from local bundle)
│  └─ README.md
│
├─ terraform/                                   ← [Planned V3.8+] VM cloning via Terraform
├─ LICENSE
└─ README.md
```

✔ What changed in V3.7.7?

- **Closes the lifecycle loop** — clone/deploy → configure → **decommission**. The toolkit now covers every stage of a VM's life on both hypervisors.
- **New playbook `decommission-vm.yml`** — permanently deletes VMs (disks + config + VMX files). Covers Proxmox + ESXi in one run. Mandatory **`confirm_decommission=yes` extra-var** gate on `localhost` before any destructive task fires. **`serial: 1`** throughout so a scoping mistake stops after one VM instead of nuking the inventory in parallel.
- **New role `proxmox_decommission`** — looks up the VM via `community.proxmox.proxmox_vm_info` (missing VM = clean skip via `meta: end_host`), forced stop, then full delete via `community.proxmox.proxmox_kvm` with `state: absent`.
- **New role `esxi_decommission`** — same shape against standalone ESXi: `community.vmware.vmware_vm_info` lookup, forced power-off via `vmware_guest_powerstate`, full delete via `community.vmware.vmware_guest` with `state: absent, force: true`.
- **Idempotent** — a VM already deleted elsewhere is skipped cleanly rather than failing the run.

✔ What changed in V3.7.6?

- **Dynamic inventory for both hypervisors** — list live VMs by querying the hypervisor API, side-by-side with the existing static `hosts.yml`:
  - `inventories/proxmox/proxmox.yml` uses the `community.proxmox.proxmox` plugin.
  - `inventories/esxi/esxi.yml` uses the `community.vmware.vmware_vm_inventory` plugin.
- **Automatic grouping** at query time:
  - Proxmox: tags become Ansible groups automatically — tagging a VM `docker_hosts` in Proxmox feeds it into the Docker specialization play with no inventory edit. Also adds `proxmox_running` / `proxmox_stopped` and `node_<nodename>` groups.
  - ESXi: adds `esxi_power_poweredOn` / `esxi_power_poweredOff` groups and a per-guest-OS group (`esxi_guest_os_*`).
- **`ansible_host` auto-filled** from the guest's real IP (Proxmox QEMU-agent on Linux, VMware Tools on ESXi), with a sensible fallback to the VM name.
- **Inventory cache** — `ansible.cfg` enables the JSONFile cache plugin with a 5-minute TTL under `./.inventory-cache/` (gitignored). Repeated `ansible-inventory` / `ansible-playbook` runs don't re-query the API every time.
- **Credentials unchanged** — the dynamic plugins reuse the same env vars as the clone/deploy flow (`PROXMOX_API_TOKEN_SECRET`, `ESXI_PASSWORD`). No new secrets.
- `enable_plugins` added to `[inventory]` in `ansible.cfg`.
- `.gitignore` adds `ansible/.inventory-cache/`.

✔ What changed in V3.7.5?

- **New role `esxi_deploy`** — deploys a VM to a **standalone ESXi** host (no vCenter) from a local OVF/OVA bundle, via `community.vmware.vmware_deploy_ovf`. Validates OVF presence with a fail-fast + an `ovftool` hint, applies optional CPU/RAM overrides via `community.vmware.vmware_guest`, powers on, and optionally waits for SSH. Thin or thick provisioning configurable per inventory.
- **Workflow note** — ESXi standalone has no `MarkAsTemplate` API, so the Packer-built VM is exported once with `ovftool` into `ansible/ovf-sources/<template>/` (gitignored, binary-heavy) and Ansible redeploys it. The one-off ovftool command is documented in `roles/esxi_deploy/README.md` and the main `ansible/README.md`.
- **New playbook `deploy-from-ovf.yml`** — parallel to `clone-from-template.yml`. Targets `esxi_clones:esxi_windows_clones` (OS-agnostic — the OVF carries the OS).
- **New inventory tree `inventories/esxi/`** — mirrors the Proxmox layout:
  - `hosts.yml` with groups `esxi_clones` (Linux), `esxi_windows_clones`, plus the specialization groups `docker_hosts` / `webservers` (semantics identical to the Proxmox side).
  - `group_vars/all.yml` — ESXi endpoint (`ESXI_HOSTNAME`), credentials (`ESXI_USERNAME`, `ESXI_PASSWORD`), datastore, network, OVF network label.
  - `group_vars/esxi_windows_clones.yml` — Windows SSH + PowerShell connection vars (same env vars as Proxmox Windows).
- **`configure-vm.yml` widened** — the Linux baseline play now targets `proxmox_clones:esxi_clones` and the Windows baseline play now targets `windows_clones:esxi_windows_clones`. Config is hypervisor-agnostic: the same role runs regardless of where the VM lives.
- **Dependencies** — added `community.vmware ≥ 4.0.0` to `requirements.yml` and `pyvmomi ≥ 8.0.0` to `requirements.txt`. Re-run `scripts/prepare-offline-bundle.sh` to refresh the air-gapped bundle.
- **`.gitignore`** — adds `ansible/ovf-sources/` (OVF binaries).

✔ What changed in V3.7.4?

- **New role `base_config_windows`** — baseline post-clone configuration for Windows 10 / 11 and Server 2019 / 2022 VMs built by the Packer side. Applied over **SSH + PowerShell** (OpenSSH Server is pre-installed by the Packer Windows templates). Covers: `win_hostname` with optional reboot via `win_reboot`, `win_timezone`, local admin user in `Administrators` group via `win_user`, SSH public key deployed to `C:\ProgramData\ssh\administrators_authorized_keys` with ACL locked to `SYSTEM` + `BUILTIN\Administrators` only, `sshd_config` hardening (`PasswordAuthentication no`, `PubkeyAuthentication yes`), and the `OpenSSH-Server-In-TCP` firewall rule enforced on port 22.
- **New inventory group `windows_clones`** — parallel to `proxmox_clones`. The clone playbook now targets `proxmox_clones:windows_clones` (the Proxmox API clone is OS-agnostic). The configure playbook gets a 4th play dedicated to `windows_clones`.
- **New `group_vars/windows_clones.yml`** — Windows connection vars (`ansible_connection: ssh`, `ansible_shell_type: powershell`), `ansible_user` from `PACKER_WINDOWS_SSH_USER` env var (default `packer`), reused `ADMIN_SSH_PUBLIC_KEY` env var for the admin key, longer clone/SSH timeouts (1200s / 600s) for Windows.
- **`ansible.windows` collection** added to `requirements.yml` (≥ 2.0.0). Re-run `prepare-offline-bundle.sh` to refresh the offline bundle if you use the air-gapped flow.
- Fail-fast on missing admin SSH key, same as the Linux `base_config` role — avoids locking the VM out.
- Explicit documentation of the Windows OpenSSH `administrators_authorized_keys` quirk in `roles/base_config_windows/README.md` (per-user `~/.ssh/authorized_keys` is ignored for admin accounts).

✔ What changed in V3.7.3?

- **Two specialized roles chained after `base_config`** on top of the existing `configure-vm.yml` playbook:
  - **`docker_host`** — installs Docker CE + Compose plugin from Docker's official apt repository (GPG key under `/etc/apt/keyrings/`, repo auto-detected from `distribution` and `distribution_release`), adds the admin user to the `docker` group, enables and starts `docker.service`. Smoke-tested with `docker --version`.
  - **`webserver`** — installs nginx, templates a demo vhost on port 80 and a hostname-aware `index.html`, disables the stock `default` vhost, validates with `nginx -t`, reloads via handler.
- **Group-based chaining** in `configure-vm.yml`: the playbook now has 3 plays — baseline (`proxmox_clones`), docker (`docker_hosts`), webserver (`webservers`). A VM only receives the plays whose inventory groups it belongs to.
- `hosts.yml` extended with the two specialization groups + commented examples (docker-host-01, web-01).
- Both specialized roles **fail fast** on non-Debian/Ubuntu guests (planned to extend once Windows baseline lands in V3.7.4).
- Note on offline sites: these two roles reach `download.docker.com` / the distro apt repo. Mirroring Docker to your internal apt mirror remains the user's infrastructure concern — out of scope for V3.7.3.

✔ What changed in V3.7.2?

- **New role `base_config`** — baseline post-clone configuration applied over SSH on Debian/Ubuntu VMs: hostname, timezone, base package set (`sudo`, `curl`, `vim`, `htop`, `net-tools`, `rsync`, `ca-certificates`, `gnupg`), a single `admin` user with the operator's SSH key and passwordless sudo, and SSH hardening (`PasswordAuthentication no`, `PermitRootLogin no`, `KbdInteractiveAuthentication no`).
- **New playbook `configure-vm.yml`** — step 2 of the lifecycle, run after `clone-from-template.yml`. Connects to each VM over SSH as the Packer-created user, applies `base_config`, and asserts `target_ip` is set in the inventory before starting.
- Role fails fast if `base_config_admin_ssh_public_key` is missing — avoids locking the VM by hardening SSH without an admin key in place.
- `group_vars/all.yml` extended with SSH connection vars (`ansible_host`, `ansible_user`, `ansible_ssh_private_key_file`) and the `base_config_*` settings. Public key passed via `ADMIN_SSH_PUBLIC_KEY` env var.
- Specialized roles (`docker_host`, `webserver`) and Windows `base_config_windows` deferred to V3.7.3 as planned.

✔ What changed in V3.7.1?

- **Offline / air-gapped support for the Ansible side** — the whole toolkit (Packer + Ansible + future Terraform) is designed to run in an internal network with no internet access. Packer already had this (plugin cache, V3.4+); Ansible now matches.
- New helper script `ansible/scripts/prepare-offline-bundle.sh`: on an **online** host, downloads every Ansible collection declared in `requirements.yml` (via `ansible-galaxy collection download`) and every Python wheel from `requirements.txt` (via `pip download`), then packs them into a single self-contained `offline-bundle-<timestamp>.tar.gz`.
- New helper script `ansible/scripts/install-offline-bundle.sh`: on the **offline** host, creates `ansible/venv/`, installs the Python deps with `pip --no-index --find-links`, and installs the Ansible collections with `ansible-galaxy collection install --offline`. No contact with PyPI or Galaxy at any point.
- Documentation added to `ansible/README.md` (dedicated "Offline / Air-Gapped setup" section) and to the roadmap.
- `.gitignore` updated to exclude `ansible/offline-bundle/`.

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
**Version:** V3.7.7  
**Contact:** [remi.rousselot91@gmail.com](mailto:remi.rousselot91@gmail.com)
