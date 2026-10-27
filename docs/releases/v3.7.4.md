# V3.7.4 — Windows baseline (`base_config_windows`)

Brings the Ansible side's Windows guest configuration to parity with the Linux `base_config` role. Applied over SSH + PowerShell, taking advantage of the OpenSSH Server already installed by the Packer Windows templates (V3.3+).

## What's new

### Role `base_config_windows`

Baseline post-clone configuration for Windows 10 / 11 and Windows Server 2019 / 2022:

- **`win_hostname`** — renames the computer; **`win_reboot`** triggered when the rename sets `reboot_required` (gated by `base_config_windows_reboot_after_rename`, default `true`).
- **`win_timezone`** — Windows TZ id (not IANA). Default `Romance Standard Time` (Paris). List valid ids on any Windows box: `tzutil /l`.
- **`win_user`** — creates a local `admin` user, member of the `Administrators` group. No interactive password is set; access is strictly via SSH key.
- **SSH key deployment** — public key written to **`C:\ProgramData\ssh\administrators_authorized_keys`**, the special shared file Windows OpenSSH uses for every member of the `Administrators` group. The per-user `~/.ssh/authorized_keys` is **ignored** for admin accounts — a well-known Windows OpenSSH quirk. ACL is explicitly reset to `SYSTEM` + `BUILTIN\Administrators` only (anything laxer causes OpenSSH to refuse the file).
- **sshd_config hardening** — `PasswordAuthentication no`, `PubkeyAuthentication yes` (gated by `base_config_windows_harden_ssh`).
- **Firewall** — ensures the `OpenSSH-Server-In-TCP` rule is enabled on port 22 via `win_firewall_rule`.

### Inventory

- New top-level group **`windows_clones`**, parallel to `proxmox_clones` (not nested) so the Linux `base_config` play never attempts to run on a Windows guest.
- New `group_vars/windows_clones.yml` with Windows SSH connection vars:
  - `ansible_connection: ssh`
  - `ansible_shell_type: powershell`
  - `ansible_user` from `PACKER_WINDOWS_SSH_USER` env var (default `packer`)
  - Longer clone/SSH timeouts (1200s / 600s)
  - Reused `ADMIN_SSH_PUBLIC_KEY` env var — one key for every VM (Linux or Windows).

### Playbooks

- `clone-from-template.yml` now targets `proxmox_clones:windows_clones` (the Proxmox API clone operation is OS-agnostic — only the Ansible API endpoint and the clone VMID differ).
- `configure-vm.yml` gains a 4th play dedicated to `windows_clones`, applying `base_config_windows`. Linux and Windows plays stay fully isolated.

### Dependencies

- Added **`ansible.windows ≥ 2.0.0`** to `requirements.yml` (needed for `win_hostname`, `win_timezone`, `win_user`, `win_copy`, `win_reboot`, `win_firewall_rule`, `win_shell`, `win_lineinfile`, `win_service`).
- Re-run `scripts/prepare-offline-bundle.sh` if you use the air-gapped flow — the new collection must land in the offline bundle.

## Typical workflow (Windows)

```bash
# Step 1 — clone + start
export PROXMOX_API_HOST=10.0.0.10
export PROXMOX_NODE=pve01
export PROXMOX_API_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
cd ansible/
ansible-playbook playbooks/clone-from-template.yml --limit windows-example-01

# Step 2 — Windows baseline
export ADMIN_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
# Optional: if the Packer admin user is not 'packer', override:
# export PACKER_WINDOWS_SSH_USER=Administrator
ansible-playbook playbooks/configure-vm.yml --limit windows-example-01

# From now on: ssh admin@<target_ip>
```

## Not included (planned)

- V3.7.5 — ESXi Ansible support (OVF deploy via `community.vmware`)
- V3.7.6 — Dynamic inventory (query Proxmox for existing VMs)
- V3.7.7 — Decommission playbook
- V3.8   — Terraform side (clone + offline support)
