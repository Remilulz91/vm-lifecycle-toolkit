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
│   └── proxmox/
│       ├── hosts.yml                    # Static list of VMs to clone (edit this!)
│       └── group_vars/
│           └── all.yml                  # Shared vars (Proxmox endpoint, user, timeouts)
├── playbooks/
│   └── clone-from-template.yml          # Entry-point: clone + optional SSH wait
├── roles/
│   └── proxmox_clone/                   # Role encapsulating the clone logic
│       ├── defaults/main.yml
│       ├── tasks/main.yml
│       └── README.md
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

- **V3.7 (current)** — Clone VMs from Packer templates (minimal, Proxmox only)
- **V3.7.1 (planned)** — Post-clone configuration roles (`base_config`, `docker_host`, `webserver`, etc.)
- **V3.7.2 (planned)** — ESXi support (OVF deploy via `community.vmware` modules)
- **V3.7.3 (planned)** — Dynamic inventory (query Proxmox for existing VMs)
- **V3.7.4 (planned)** — Decommission playbook (clean VM teardown)

## 📜 License

See the top-level [LICENSE](../LICENSE) file. This directory is covered by the same proprietary license as the rest of the VM Lifecycle Toolkit.
