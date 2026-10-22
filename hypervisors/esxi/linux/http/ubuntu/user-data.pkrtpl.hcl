#cloud-config
autoinstall:
  version: 1
  locale: fr_FR.UTF-8
  keyboard:
    layout: fr
    variant: ''
  timezone: Europe/Paris

  # Offline build: skip the installer's snap-store refresh (no internet)
  refresh-installer:
    update: false

  # Offline build: don't reconfigure apt sources, don't probe geoIP,
  # continue even if APT setup fails.
  apt:
    geoip: false
    preserve_sources_list: true
    fallback: continue-anyway

  # Network configuration (DHCP on all interfaces)
  network:
    network:
      version: 2
      ethernets:
        main:
          match:
            name: e*
          dhcp4: true

  # Main machine identity
  identity:
    hostname: ${hostname}
    realname: ${user_username}
    username: ${user_username}
    # The Ubuntu installer requires a hashed password here by default.
    # We use a generic dummy hash, and we enforce the real clear-text 
    # passwords via the chpasswd block below.
    password: "$6$rounds=4096$randomsalt$X"

  # SSH server activation
  ssh:
    install-server: true
    allow-pw: true

  # Automatic partitioning (equivalent to atomic partman)
  storage:
    layout:
      name: direct

  # open-vm-tools provides the vSphere guest tools (paravirtualization helpers,
  # IP reporting to ESXi, time sync, graceful shutdown). It's on the live-server
  # ISO so no internet is needed.
  packages:
    - open-vm-tools

  # User-data passed to cloud-init in the installed system (runs at first boot)
  user-data:
    # 1. Define clear-text passwords for Root and the standard user
    chpasswd:
      list: |
        root:${root_password}
        ${user_username}:${user_password}
      expire: false
    # 2. Create a drop-in file to allow Root SSH login for Packer
    write_files:
      - path: /etc/ssh/sshd_config.d/99-packer-ssh.conf
        content: |
          PermitRootLogin yes
          PasswordAuthentication yes
          PubkeyAuthentication yes
    # 3. Restart the SSH service to apply the configuration
    runcmd:
      - systemctl restart ssh
