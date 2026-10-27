# --- QEMU site settings ---
# No remote hypervisor: builds happen on the host that runs Packer.

# Accelerator — "kvm" on a Linux host with /dev/kvm, "tcg" otherwise (slow).
qemu_accelerator = "kvm"

# Headless build (no QEMU window). Flip to false while debugging an install.
qemu_headless = true

# Guest devices (defaults match what libvirt/cockpit-machines expect).
disk_interface = "virtio-scsi"
net_device     = "virtio-net"
disk_format    = "qcow2"

# Leave empty to use Packer's default `output-<template_name>/`.
# Set to e.g. "/var/lib/libvirt/images/vm-lifecycle-toolkit"
# to drop artefacts directly into a libvirt storage pool.
output_directory = ""
