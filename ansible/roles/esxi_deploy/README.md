# Role: `esxi_deploy`

Deploys a VM from a local OVF/OVA bundle to a **standalone ESXi** host (no vCenter required), using `community.vmware.vmware_deploy_ovf`.

Equivalent of `proxmox_clone` for the ESXi side, with one architectural difference: standalone ESXi has no `MarkAsTemplate` API, so the Packer-built "template" is exported once to OVF with `ovftool`, and Ansible redeploys that OVF to create new VMs.

## Workflow overview

```
Packer build                 ovftool (once, manual)         Ansible (this role)
─────────────                ────────────────────           ───────────────────
VM on ESXi            →      debian-13.ovf        →         VM on ESXi
("Packer-built-template")    debian-13.vmdk                 (one per clone)
                             (stored on controller
                              under ovf-sources/)
```

## What it does

1. Validates required inventory variables (`source_ovf_dir`, `source_ovf_file`, `target_name`, etc.).
2. Checks that the OVF/OVA file exists on the controller (fail-fast with helpful ovftool hint if not).
3. Deploys the OVF via `community.vmware.vmware_deploy_ovf` to the host defined by `esxi_hostname` + credentials from group_vars.
4. Applies optional CPU/RAM overrides (`target_cores`, `target_memory_mb`) via `community.vmware.vmware_guest`.
5. Powers on the VM.
6. Optionally waits for SSH on `target_ip`.

## Exporting the OVF from Packer (operator step, one-off)

Install [VMware ovftool](https://developer.vmware.com/web/tool/ovf) once on the controller, then:

```bash
# Export a Packer-built VM named 'debian-13-template' from ESXi host esxi.lan
# into the directory ansible/ovf-sources/debian-13/
ovftool \
  vi://root@esxi.lan/debian-13-template \
  ansible/ovf-sources/debian-13/debian-13.ovf
```

The directory `ansible/ovf-sources/` is in `.gitignore` — never commit OVF binaries.

## Required variables

Per-host (in `inventories/esxi/hosts.yml`):

| Variable | Why |
|---|---|
| `source_ovf_dir`  | Subfolder under `esxi_deploy_ovf_base_dir` holding the OVF |
| `source_ovf_file` | OVF/OVA file name inside `source_ovf_dir` (e.g. `debian-13.ovf`) |
| `target_name`     | Name shown in the ESXi UI for the new VM |

Group-level (in `inventories/esxi/group_vars/all.yml`):

| Variable | Example |
|---|---|
| `esxi_hostname`       | `esxi01.lan` |
| `esxi_username`       | `root` |
| `esxi_password`       | from env `ESXI_PASSWORD` |
| `esxi_validate_certs` | `false` (self-signed) |
| `esxi_datastore`      | `datastore1` |
| `esxi_network`        | `VM Network` |

## Main defaults

| Variable | Default |
|---|---|
| `esxi_deploy_ovf_base_dir` | `{{ playbook_dir }}/../ovf-sources` |
| `esxi_deploy_disk_provisioning` | `thin` |
| `esxi_deploy_timeout_seconds` | `1800` |
| `esxi_deploy_ssh_wait_timeout_seconds` | `600` |

## Post-deploy

After deploy, the VM is a regular ESXi VM. Running `playbooks/configure-vm.yml` with the ESXi inventory applies the same `base_config` (Linux) or `base_config_windows` (Windows) role as for Proxmox-cloned VMs — the config side is hypervisor-agnostic.
