# V3.7.3 — Specialized roles: `docker_host` + `webserver`

Two app-specific roles layered on top of `base_config`, chained via inventory groups in a single `configure-vm.yml` playbook.

## What's new

### Role `docker_host`
- Installs Docker CE + Compose plugin from Docker's official apt repository.
- GPG key placed under `/etc/apt/keyrings/docker.asc`, repo auto-detected from `ansible_facts.distribution` (`linux/debian` or `linux/ubuntu`) and `distribution_release`.
- Architecture auto-detected (`amd64` / `arm64`) from `ansible_facts.architecture`.
- Admin user (default: the one created by `base_config`) added to the `docker` group.
- Service enabled and started, smoke-tested with `docker --version`.
- Fails fast on non-Debian/Ubuntu guests.

### Role `webserver`
- Installs nginx on Debian / Ubuntu.
- Templates a demo vhost in `/etc/nginx/sites-available/` and symlinks it into `sites-enabled/`.
- Removes the stock `default` symlink to free port 80.
- Templates a hostname-aware `index.html` under `/var/www/<site_name>/`.
- Runs `nginx -t` for validation, enables and starts the service, reloads via handler on config change.

### Playbook `configure-vm.yml`
- Now has **three plays** instead of one:
  1. `proxmox_clones` → `base_config`
  2. `docker_hosts` → `docker_host`
  3. `webservers` → `webserver`
- A VM only receives the plays whose inventory groups it belongs to.

### Inventory
- `hosts.yml` gains two new specialization groups (`docker_hosts`, `webservers`) with commented examples (`docker-host-01`, `web-01`).

## Example inventory snippet

```yaml
all:
  children:
    proxmox_clones:
      hosts:
        docker-host-01:
          source_template_vmid: 1001        # Debian 13 template
          target_vmid: 2010
          target_name: "docker-host-01"
          target_ip: "192.168.1.210"
        web-01:
          source_template_vmid: 1002        # Ubuntu Server template
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

## Not included (planned)

- V3.7.4 — Windows baseline (`base_config_windows`)
- V3.7.5 — ESXi Ansible support
- V3.7.6 — Dynamic inventory (query Proxmox for existing VMs)
- V3.7.7 — Decommission playbook
- V3.8   — Terraform side (clone + offline support)

## Notes on offline / air-gapped sites

Both new roles reach the internet by default (`download.docker.com` for `docker_host`, the distro apt mirror for `webserver`). On a true air-gapped site you need an internal apt mirror and (for Docker) a mirror of `download.docker.com`. Mirroring is infrastructure plumbing and remains the operator's responsibility — it is intentionally out of scope for V3.7.3.
