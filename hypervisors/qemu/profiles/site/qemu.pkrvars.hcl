# --- QEMU site settings ---
# No remote hypervisor: builds happen on the host that runs Packer.

# Accelerator — "kvm" on a Linux host with /dev/kvm, "tcg" otherwise (slow).
qemu_accelerator = "kvm"

# Headless build (no QEMU window). Flip to false while debugging an install.
qemu_headless = true

# VNC exposure.
# Default "0.0.0.0" so VNC is reachable from your workstation on the LAN
# (matches the "it just worked" behaviour of the Gemini test setup).
# Port is pinned to 5900 so a VNC client always points at the same place.
# Flip qemu_vnc_bind_address to "127.0.0.1" + SSH-tunnel if you need the
# VNC port kept off the LAN.
qemu_vnc_bind_address = "0.0.0.0"
qemu_vnc_port_min     = 5900
qemu_vnc_port_max     = 5900

# Guest devices (defaults match what libvirt/cockpit-machines expect).
disk_interface = "virtio-scsi"
net_device     = "virtio-net"
disk_format    = "qcow2"

# Leave empty to use Packer's default `output-<template_name>/`.
# Set to e.g. "/var/lib/libvirt/images/vm-lifecycle-toolkit"
# to drop artefacts directly into a libvirt storage pool.
output_directory = ""
