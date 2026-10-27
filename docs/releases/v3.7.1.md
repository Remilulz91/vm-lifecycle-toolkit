# V3.7.1 — Offline / air-gapped support for the Ansible side

The whole VM Lifecycle Toolkit is designed to run inside an **internal network with no internet access** (Packer builds already supported this since V3.4). V3.7.1 brings the Ansible side to parity.

## What's new

- **`ansible/scripts/prepare-offline-bundle.sh`** — run this on an **online** machine. It uses `ansible-galaxy collection download` + `pip download` to fetch every dependency declared in `requirements.yml` and `requirements.txt`, and packs them into a single `offline-bundle-<timestamp>.tar.gz`.
- **`ansible/scripts/install-offline-bundle.sh`** — run this on the **offline / air-gapped** machine, after transferring and extracting the archive. It creates `ansible/venv/`, installs the Python deps with `pip --no-index --find-links`, and installs the Ansible collections with `ansible-galaxy collection install --offline`. **No contact with PyPI or Galaxy at any point.**
- **Dedicated "Offline / Air-Gapped setup" section** in `ansible/README.md` with the 4-step workflow (prepare → transfer → install → run).
- `.gitignore` now excludes `ansible/offline-bundle/`.

## Quick workflow

```bash
# ---------- ONLINE host ----------
cd ansible/
bash scripts/prepare-offline-bundle.sh
# → ansible/offline-bundle/offline-bundle-YYYYMMDD-HHMMSS.tar.gz

# ---------- Transfer the single .tar.gz ----------
# USB stick, internal share, scp through a bastion, …

# ---------- OFFLINE host ----------
tar xzf offline-bundle-YYYYMMDD-HHMMSS.tar.gz
bash ansible/scripts/install-offline-bundle.sh ./staging

source ansible/venv/bin/activate
export PROXMOX_API_HOST=... PROXMOX_NODE=... PROXMOX_API_TOKEN_SECRET=...
cd ansible/
ansible-playbook playbooks/clone-from-template.yml
```

## Not included (planned for later)

- Terraform offline flow (`terraform providers mirror`) — will land in V3.8 together with the Terraform side itself.
- Post-clone configuration roles — still V3.7.2.
- ESXi Ansible support — still V3.7.3.
