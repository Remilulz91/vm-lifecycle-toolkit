# Role: `webserver`

Installs nginx and deploys a demo vhost on Debian / Ubuntu VMs.

## What it does

1. Installs the `nginx` apt package.
2. Creates the document root at `/var/www/<site_name>/`.
3. Templates a demo `index.html` showing the hostname and role identity.
4. Templates a vhost config (`sites-available/<site_name>.conf`) and symlinks it into `sites-enabled/`.
5. Removes the stock `default` symlink from `sites-enabled/` (prevents the `:80` conflict).
6. Runs `nginx -t` as a validation step, enables and starts the service, reloads via handler when the vhost or index change.

## Applied via inventory group

```yaml
all:
  children:
    proxmox_clones:
      hosts:
        web-01:
          source_template_vmid: 1002
          target_vmid: 2020
          target_name: "web-01"
          target_ip: "192.168.1.220"
    webservers:
      hosts:
        web-01:
```

A host in `webservers` must also be in `proxmox_clones` (so it gets `base_config` first and the SSH connection vars).

## Main defaults

| Variable | Default |
|---|---|
| `webserver_site_name` | `default-site` |
| `webserver_server_name` | `{{ inventory_hostname }}` |
| `webserver_listen_port` | `80` |
| `webserver_document_root` | `/var/www/{{ webserver_site_name }}` |
| `webserver_welcome_message` | *(auto-generated identity string)* |

## Purpose

This role is intentionally minimal — it illustrates the "specialized role" pattern (how to layer app-specific config on top of `base_config`) rather than aiming to be a production nginx role.
