### --- Locale & Keyboard ---
d-i debian-installer/locale string fr_FR.UTF-8
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select fr
d-i keyboard-configuration/layoutcode string fr
d-i keyboard-configuration/modelcode string pc105

### --- Network & Mirror ---
# Hostname comes from Packer (template_name)
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string ${hostname}
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

### --- Timezone ---
d-i time/zone string Europe/Paris
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true

### --- Partitioning (entire disk, auto-confirm everything) ---
# Target disk
d-i partman-auto/disk string /dev/sda
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic

# Remove any existing LVM/RAID metadata without asking
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-md/device_remove_md boolean true

# Write the new label and finish without prompts
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Install GRUB on /dev/sda without prompt
d-i grub-installer/bootdev string /dev/sda

### --- Users ---
# Root account (enabled temporarily for first SSH; provisioner will enforce key-only later)
d-i passwd/root-login boolean true
d-i passwd/root-password password ${root_password}
d-i passwd/root-password-again password ${root_password}

# Standard user (non-sudoer, password auth enabled)
d-i passwd/user-fullname string ${user_username}
d-i passwd/username string ${user_username}
d-i passwd/user-password password ${user_password}
d-i passwd/user-password-again password ${user_password}
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

### --- Packages & APT setup ---
# Offline build: install packages from the DVD only, no HTTP mirror
d-i apt-setup/use_mirror boolean false
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true
# For Debian 12+ (Bookworm), enable non-free-firmware too:
d-i apt-setup/non-free-firmware boolean true

tasksel tasksel/first multiselect standard
# Only install what is needed from the DVD: SSH server, sudo, ca-certificates.
# (open-vm-tools is installed separately by the late_command — see below — because
# it is referenced in the DVD-1 Packages index but its .deb is not on DVD-1.)
d-i pkgsel/include string openssh-server sudo ca-certificates
d-i pkgsel/upgrade select none

### --- Bootloader ---
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true

### --- Finish installation ---
d-i finish-install/reboot_in_progress note

### --- Late command (post-install: install offline .debs + enable initial root SSH for Packer) ---
# 1. Download .deb files served by Packer's HTTP server and install them with dpkg -i
#    (this is how open-vm-tools and any other DVD-missing packages get installed offline).
# 2. Enable root SSH login (key + password) so Packer can connect on first boot.
#    The build provisioner will harden this later (key-only, PermitRootLogin prohibit-password).
d-i preseed/late_command string \
  HTTP_BASE=$(tr ' ' '\n' < /proc/cmdline | grep '^url=' | sed 's|^url=||; s|/preseed\.cfg$||') && \
  mkdir -p /target/tmp/debs && \
  wget -q -O /tmp/manifest.txt "$${HTTP_BASE}/debs/manifest.txt" && \
  while IFS= read -r deb || [ -n "$deb" ]; do \
    [ -n "$deb" ] && wget -q -O- "$${HTTP_BASE}/debs/$${deb}.b64" | base64 -d > "/target/tmp/debs/$${deb}" ; \
  done < /tmp/manifest.txt && \
  in-target sh -c 'dpkg -i /tmp/debs/*.deb' && \
  in-target sh -c "set -eux; \
    sed -i 's/^#\\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config; \
    sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config; \
    if grep -q '^PermitRootLogin' /etc/ssh/sshd_config; then \
      sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    else \
      echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config; \
    fi; \
  "
