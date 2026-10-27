# Role: `docker_host`

Installs Docker CE and the Compose plugin from Docker's official apt repository on Debian / Ubuntu VMs.

## What it does

1. Installs prerequisites (`ca-certificates`, `curl`, `gnupg`).
2. Downloads Docker's apt GPG key to `/etc/apt/keyrings/docker.asc` (uses the distribution-specific URL — `linux/debian` or `linux/ubuntu`).
3. Adds the Docker apt repository for the running release (`{{ ansible_facts.distribution_release }}`), with architecture auto-detection (`amd64` / `arm64`).
4. Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`.
5. Enables and starts `docker.service`.
6. Adds the admin user (configurable) to the `docker` group so it can run `docker` without `sudo`.
7. Prints the installed version as a smoke test.

## Applied via inventory group

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
    docker_hosts:
      hosts:
        docker-host-01:
```

A host in `docker_hosts` **must also** be in `proxmox_clones` (so it gets `base_config` first and the SSH connection vars).

## Main defaults

| Variable | Default |
|---|---|
| `docker_host_users` | `[ "{{ base_config_admin_user | default('admin') }}" ]` |
| `docker_host_packages` | `[docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin]` |
| `docker_host_service_enabled` | `true` |
| `docker_host_service_state` | `started` |

## Note on offline / air-gapped sites

This role uses `apt` and reaches `download.docker.com` for the GPG key + repo. On a true air-gapped site, mirror the Docker repository to your internal apt mirror and override the GPG key + repo URL via overrides, or install the Docker `.deb` files directly from a local bundle. That workflow is out of scope for V3.7.3.
