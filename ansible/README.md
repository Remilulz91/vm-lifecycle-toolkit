# 🤖 Ansible — VM Lifecycle Toolkit

This directory contains the **Ansible side** of the VM Lifecycle Toolkit: playbooks and roles to **clone VMs from Packer-built templates** and (in future versions) configure them.

For a project overview, see the top-level [README.md](../README.md).
For the detailed build/setup guide for Packer and hypervisor hosts, see [BUILD.md](../BUILD.md).

## 📁 Layout

```
ansible/
├── ansible.cfg                          # Ansible config (inventory, SSH, collection path)
├── requirements.yml                     # Ansible collections (community.general, ansible.posix)
├── requirements.txt                     # Python dependencies (proxmoxer, requests)
├── inventories/
│   ├── proxmox/
│   │   ├── hosts.yml                    # Static list of VMs to clone on Proxmox
│   │   ├── proxmox.yml                  ← V3.7.6: Dynamic inventory (live VM list)
│   │   └── group_vars/
│   │       ├── all.yml                  # Proxmox endpoint, user, timeouts, SSH
│   │       └── windows_clones.yml       # Windows SSH + PowerShell vars
│   └── esxi/                            ← V3.7.5: Standalone ESXi deploy
│       ├── hosts.yml                    # Static list of VMs to deploy on ESXi
│       ├── esxi.yml                     ← V3.7.6: Dynamic inventory (live VM list)
│       └── group_vars/
│           ├── all.yml                  # ESXi endpoint, datastore, network
│           └── esxi_windows_clones.yml  # Windows SSH + PowerShell vars
├── playbooks/
│   ├── clone-from-template.yml          # Step 1 (Proxmox): clone + start
│   ├── deploy-from-ovf.yml              # Step 1 (ESXi): deploy OVF + start
│   ├── configure-vm.yml                 # Step 2: SSH-based baseline config (both hypervisors)
│   └── decommission-vm.yml              ← V3.7.7: Destructive teardown (both hypervisors)
├── roles/
│   ├── proxmox_clone/                   # Role: clone + optional SSH wait
│   │   ├── defaults/main.yml
│   │   ├── tasks/main.yml
│   │   └── README.md
│   ├── base_config/                     # Role: hostname, tz, admin user, SSH hardening
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml
│   │   └── README.md
│   ├── docker_host/                     # V3.7.3: Install Docker CE + Compose plugin
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml
│   │   └── README.md
│   ├── webserver/                       # V3.7.3: Install nginx + demo vhost
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml
│   │   ├── templates/vhost.conf.j2
│   │   ├── templates/index.html.j2
│   │   └── README.md
│   ├── base_config_windows/             # V3.7.4: Windows baseline (hostname, tz, admin, SSH)
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml
│   │   └── README.md
│   ├── esxi_deploy/                     # V3.7.5: Deploy VM from OVF to standalone ESXi
│   │   ├── defaults/main.yml
│   │   ├── tasks/main.yml
│   │   └── README.md
│   ├── proxmox_decommission/            # V3.7.7: Stop + delete a Proxmox VM
│   │   ├── tasks/main.yml
│   │   └── README.md
│   └── esxi_decommission/               # V3.7.7: Power-off + delete an ESXi VM
│       ├── tasks/main.yml
│       └── README.md
├── scripts/
│   ├── prepare-offline-bundle.sh        # (online host) build an air-gapped bundle
│   └── install-offline-bundle.sh        # (offline host) install from that bundle
└── README.md                            # This file
```

## 🛠️ Prerequisites

### 1. A Packer-built template on your Proxmox host

See the top-level [BUILD.md](../BUILD.md) for how to build templates with Packer. Note the **VMID** of the template you want to clone from — you'll reference it in the Ansible inventory below.

### 2. Dedicated `ansible@pam` user on Proxmox

See [BUILD.md — "Ansible setup"](../BUILD.md) for the exact `pveum` commands. In short:

```bash
pveum user add ansible@pam
pveum aclmod / -user ansible@pam -role PVEVMAdmin
pveum aclmod /storage/local -user ansible@pam -role PVEDatastoreAdmin
pveum aclmod /storage/local-lvm -user ansible@pam -role PVEDatastoreAdmin
pveum aclmod /sdn/zones/localnetwork -user ansible@pam -role PVESDNUser
pveum user token add ansible@pam ci --privsep 0
```

Note the token **secret** that is printed — you'll pass it at runtime via an environment variable.

### 3. Local dependencies (on the controller — the machine that runs `ansible-playbook`)

#### 3.a Python dependencies — venv recommended

> ⚠️ **Debian 13 / Ubuntu 24.04 note**: the system package `python3-proxmoxer` ships **version 2.2.0**, which is **too old** for the current `community.proxmox` collection (requires proxmoxer **≥ 2.3**). You cannot use `sudo apt install python3-proxmoxer` alone — you need pip-based install. And `pip install` directly on the system Python is blocked by PEP 668. **→ Use a venv.**

**Option A — Virtual environment (recommended, cross-distro)**

```bash
cd ansible/
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Reactivate the venv before every session with `source venv/bin/activate`. The `venv/` directory is already ignored by `.gitignore`.

**Option B — Break system packages (last resort, Debian/Ubuntu)**

```bash
# If python3-proxmoxer 2.2 is already installed, remove it first to avoid conflicts:
sudo apt remove python3-proxmoxer python3-requests

# Install the pip version system-wide, overriding PEP 668:
pip install --break-system-packages -r requirements.txt
```

Only use this if you understand the risk of conflicts with your distro's system Python packages.

**Note**: a pure `sudo apt install python3-proxmoxer python3-requests` is NOT sufficient on Debian 13 / Ubuntu 24.04 because the apt-shipped version of proxmoxer is behind the one the Ansible modules need. If your distro ever packages proxmoxer 2.3+, that option becomes viable again.

#### 3.b Ansible collections

Installed into `./collections/` (not system-wide), so no `sudo` needed:

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
```

## 🚀 Quick start

### 1. Set credentials via environment variables

```bash
export PROXMOX_API_HOST=192.168.1.10
export PROXMOX_NODE=pve01
export PROXMOX_API_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

(The secret value is what Proxmox printed when you ran `pveum user token add ...` above.)

### 2. Describe the VM(s) you want to clone

Edit `inventories/proxmox/hosts.yml` and add one entry per VM:

```yaml
all:
  children:
    proxmox_clones:
      hosts:
        my-new-debian:
          source_template_vmid: 1001        # VMID of the Packer-built Debian template
          target_vmid: 2010                 # Must be free + >= 1000
          target_name: "my-new-debian"
          target_cores: 4                   # Optional
          target_memory_mb: 8192            # Optional
          target_ip: "192.168.1.210"        # Optional — if set, Ansible waits for SSH on this IP
```

### 3. Run the clone playbook

From the `ansible/` directory:

```bash
# Clone every VM listed in the inventory
ansible-playbook playbooks/clone-from-template.yml

# Or clone one specific VM only
ansible-playbook playbooks/clone-from-template.yml --limit my-new-debian
```

### 4. Apply the baseline configuration (V3.7.2+)

Once the VM is cloned, started, and reachable on `target_ip`, apply the baseline (hostname, timezone, base packages, admin user, SSH hardening):

```bash
# Public SSH key to deploy to the new 'admin' user on every VM
export ADMIN_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"

# Optional overrides for how Ansible SSHes into the Packer-built VM
# (defaults: user=packer, key=~/.ssh/id_ed25519)
# export PACKER_SSH_USER=packer
# export PACKER_SSH_PRIVATE_KEY=~/.ssh/id_ed25519

ansible-playbook playbooks/configure-vm.yml
# or just one VM:
ansible-playbook playbooks/configure-vm.yml --limit my-new-debian
```

After the playbook runs, SSH as the new admin: `ssh admin@<target_ip>`. Password authentication and root login are disabled.

### 5. Apply specialized roles (V3.7.3+)

List your VMs in the specialization groups of `inventories/proxmox/hosts.yml` to layer app-specific roles on top of `base_config`:

```yaml
all:
  children:
    proxmox_clones:
      hosts:
        docker-host-01:
          source_template_vmid: 1001
          target_vmid: 2010
          target_name: "docker-host-01"
          target_ip: "192.168.1.210"
        web-01:
          source_template_vmid: 1002
          target_vmid: 2020
          target_name: "web-01"
          target_ip: "192.168.1.220"
    docker_hosts:
      hosts:
        docker-host-01:
    webservers:
      hosts:
        web-01:
```

Then rerun `configure-vm.yml`. Each VM gets `base_config` first, then any specialization play whose group it belongs to:

- `docker_hosts`: installs Docker CE + Compose plugin, adds `admin` to the `docker` group. See [roles/docker_host/README.md](roles/docker_host/README.md).
- `webservers`: installs nginx and deploys a demo vhost on port 80. See [roles/webserver/README.md](roles/webserver/README.md).

### 6. Windows VMs (V3.7.4+)

List Windows targets under the **`windows_clones`** group — a parallel group to `proxmox_clones`, not nested under it (keeps the Linux and Windows plays cleanly separated and avoids running `base_config` on a Windows guest):

```yaml
all:
  children:
    windows_clones:
      hosts:
        windows-example-01:
          source_template_vmid: 1101
          target_vmid: 2101
          target_name: "windows-ex-01"       # <= 15 chars (NetBIOS)
          target_cores: 4
          target_memory_mb: 8192
          target_ip: "192.168.1.230"
```

`clone-from-template.yml` targets `proxmox_clones:windows_clones` (both at once — the Proxmox API clone is OS-agnostic). `configure-vm.yml` has a 4th play dedicated to `windows_clones` that applies the `base_config_windows` role.

Connection to Windows is **SSH + PowerShell** (OpenSSH Server is pre-installed by the Packer Windows templates):
- `ansible_connection: ssh`
- `ansible_shell_type: powershell`
- `ansible_user`: the Packer admin user (default `packer`, override via `PACKER_WINDOWS_SSH_USER`)
- Same `ADMIN_SSH_PUBLIC_KEY` env var as the Linux role — one key for all VMs

The Windows admin user's authorized key goes to **`C:\ProgramData\ssh\administrators_authorized_keys`** (the OpenSSH Windows quirk: per-user `~/.ssh/authorized_keys` is ignored for anyone in the Administrators group). The role sets the ACL on that file to `SYSTEM` + `BUILTIN\Administrators` only.

### 7. Standalone ESXi (V3.7.5+)

ESXi standalone has no `MarkAsTemplate` API, so the deploy flow differs: export the Packer-built VM to OVF once with `ovftool`, store the OVF under `ansible/ovf-sources/<template>/`, then let Ansible redeploy it to the ESXi host via `community.vmware.vmware_deploy_ovf`.

**One-off export** (uses VMware's [ovftool](https://developer.vmware.com/web/tool/ovf)):

```bash
ovftool \
  vi://root@esxi01.lan/debian-13-template \
  ansible/ovf-sources/debian-13/debian-13.ovf
```

**Deploy and configure**:

```bash
export ESXI_HOSTNAME=esxi01.lan
export ESXI_PASSWORD=xxxxxxxx
# (optional) ESXI_USERNAME, ESXI_DATASTORE, ESXI_NETWORK

ansible-playbook -i inventories/esxi/ playbooks/deploy-from-ovf.yml

export ADMIN_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
ansible-playbook -i inventories/esxi/ playbooks/configure-vm.yml
```

The configure playbook stays the same — `base_config` and `base_config_windows` run identically whether the VM came from Proxmox or ESXi.

The directory `ansible/ovf-sources/` is `.gitignore`'d — never commit OVF binaries.

### 8. Dynamic inventory (V3.7.6+)

Static `hosts.yml` is right for *provisioning* (listing VMs you want to clone/deploy). For *operating* on VMs that already exist, there are now two dynamic-inventory plugin configs that query the hypervisors directly:

- `inventories/proxmox/proxmox.yml` → `community.proxmox.proxmox` plugin
- `inventories/esxi/esxi.yml`       → `community.vmware.vmware_vm_inventory` plugin

Both files live **next to** `hosts.yml`. Ansible merges every inventory source in a directory, so pointing `-i` at the directory gives you the union: static entries (planned clones/deploys) + live VMs returned by the plugin.

```bash
# See what's live right now
ansible-inventory -i inventories/proxmox/ --graph
ansible-inventory -i inventories/esxi/    --graph

# Ad-hoc ping on every running Proxmox VM the token can see
ansible -i inventories/proxmox/ proxmox_running -m ansible.builtin.ping

# Re-apply the baseline to one specific live VM (no need to edit hosts.yml)
ansible-playbook -i inventories/proxmox/ playbooks/configure-vm.yml \
    --limit some-existing-vm
```

**Automatic groupings**:
- Proxmox tags become Ansible groups. Tag a VM `docker_hosts` in Proxmox → it feeds into the Docker specialization play without any inventory edit.
- Proxmox adds `proxmox_running` / `proxmox_stopped`, and a `node_<nodename>` group per hypervisor node.
- ESXi adds `esxi_power_poweredOn` / `esxi_power_poweredOff` and a `esxi_guest_os_*` group per guest-OS family.

**Credentials** reuse the same env vars as the clone/deploy flow (`PROXMOX_API_TOKEN_SECRET`, `ESXI_PASSWORD`). No new secrets.

**Caching**: `ansible.cfg` enables the JSONFile cache (5-minute TTL) under `./.inventory-cache/` (gitignored) — so repeated `ansible-inventory`/`ansible-playbook` runs don't hammer the hypervisor API. Clear it manually with `rm -rf .inventory-cache/` if you need a fresh fetch.

### 9. Decommissioning VMs (V3.7.7+)

The `decommission-vm.yml` playbook permanently deletes VMs — disks, config, VMX files, the lot. It covers both hypervisors in one run and is **safety-gated**: it refuses to start without an explicit extra-var.

```bash
# Decommission ONE Proxmox VM (safest form)
ansible-playbook -i inventories/proxmox/ playbooks/decommission-vm.yml \
    --limit debian-example-01 \
    -e confirm_decommission=yes

# Decommission ONE ESXi VM
ansible-playbook -i inventories/esxi/ playbooks/decommission-vm.yml \
    --limit debian-esxi-01 \
    -e confirm_decommission=yes
```

Design properties:

- **Explicit confirmation** — the first play runs on `localhost` and asserts `confirm_decommission=yes`. Any other value, or omission, aborts the run before any API call fires.
- **`serial: 1`** — VMs are torn down one at a time. If you mistakenly target too wide a scope, the mistake stops after the first VM and the rest survive.
- **Idempotent** — a VM that's already gone (another operator deleted it, or the role already ran) is skipped cleanly via `meta: end_host`, not treated as an error.
- **Same groups as clone/deploy** — `proxmox_clones` + `windows_clones` on the Proxmox side, `esxi_clones` + `esxi_windows_clones` on the ESXi side.

## 📦 Offline / Air-Gapped setup

The entire VM Lifecycle Toolkit is designed to also run in an **air-gapped internal network** with no internet access. The Packer side already supports this (plugin cache — see top-level [BUILD.md](../BUILD.md)). The Ansible side has the same workflow via two helper scripts in `ansible/scripts/`.

### Step 1 — On an ONLINE machine: build the bundle

```bash
cd ansible/
bash scripts/prepare-offline-bundle.sh
```

The script runs `ansible-galaxy collection download` + `pip download` and packs everything into a single archive:

```
ansible/offline-bundle/offline-bundle-YYYYMMDD-HHMMSS.tar.gz
```

That archive contains:
- All Ansible collections declared in `requirements.yml` (as `.tar.gz`)
- All Python wheels needed by `requirements.txt` (proxmoxer, requests + transitive deps)
- A copy of both requirements files

### Step 2 — Transfer the archive

Use whichever path you have into the air-gapped zone: USB stick, internal file share, `scp` through a bastion, etc. The archive is self-contained — nothing else to transfer.

### Step 3 — On the OFFLINE machine: install from the bundle

```bash
# Extract the archive next to the ansible/ directory
tar xzf offline-bundle-YYYYMMDD-HHMMSS.tar.gz
# This creates ./staging/ with collections/, wheels/, requirements.yml, requirements.txt

# Install everything (no internet, no PyPI, no Galaxy):
bash ansible/scripts/install-offline-bundle.sh ./staging
```

The script creates `ansible/venv/`, installs Python deps with `pip --no-index --find-links`, and installs the Ansible collections into `ansible/collections/` with `ansible-galaxy collection install --offline`.

### Step 4 — Run the playbook as usual

```bash
source ansible/venv/bin/activate
export PROXMOX_API_HOST=10.0.0.10
export PROXMOX_NODE=pve01
export PROXMOX_API_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

cd ansible/
ansible-playbook playbooks/clone-from-template.yml
```

### Rebuilding the bundle

Whenever `requirements.yml` or `requirements.txt` is updated, re-run `prepare-offline-bundle.sh` on the online machine and transfer the fresh archive. The install script will overwrite the previous collections/wheels in place.

## 🔐 Secrets handling

The API token secret is passed via the `PROXMOX_API_TOKEN_SECRET` environment variable — **never commit it to git**. For production use, consider encrypting a dedicated vars file with `ansible-vault` instead.

Example `ansible-vault` approach:

```bash
# Create an encrypted vars file holding the secret
ansible-vault create inventories/proxmox/group_vars/vault.yml
# Inside: proxmox_api_token_secret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Then run with --ask-vault-pass or --vault-password-file
ansible-playbook playbooks/clone-from-template.yml --ask-vault-pass
```

Make sure to override the `proxmox_api_token_secret` lookup in `group_vars/all.yml` accordingly if you take this path.

## 🔮 Roadmap

- **V3.7**             — Clone VMs from Packer templates (minimal, Proxmox only)
- **V3.7.1**           — Offline / air-gapped bundle scripts for Ansible deps
- **V3.7.2**           — Baseline post-clone role `base_config` + `configure-vm.yml` playbook (Debian/Ubuntu)
- **V3.7.3**           — Specialized roles: `docker_host` + `webserver` (nginx), chained via inventory groups
- **V3.7.4**           — Windows baseline role `base_config_windows` + `windows_clones` inventory group
- **V3.7.5**           — Standalone ESXi deploy via OVF (`esxi_deploy` role + `inventories/esxi/` + `deploy-from-ovf.yml`)
- **V3.7.6**           — Dynamic inventory for Proxmox + ESXi (`inventories/*/proxmox.yml` and `esxi.yml`), inventory cache
- **V3.7.7 (current)** — Decommission playbook + roles (`decommission-vm.yml`, `proxmox_decommission`, `esxi_decommission`) with a mandatory confirmation gate

## 📜 License

See the top-level [LICENSE](../LICENSE) file. This directory is covered by the same proprietary license as the rest of the VM Lifecycle Toolkit.
