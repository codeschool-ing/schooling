#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of virtualization, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. The computer is called host
# and runs Ubuntu 24.04 with QEMU and libvirt; every other name is one of its
# guests, a real virtual machine made by lab.sh from Ubuntu's minimal cloud
# image. A line that starts with ana@host ran on the computer itself, and one
# that starts with ana@vm1 ran inside the guest called vm1, reached with ssh.
#
# The computer the lab was recorded on is itself a virtual machine without
# nested virtualisation, so QEMU emulates the guests' processor in software
# (--virt-type qemu). With VT-x or AMD-V, the same commands take kvm.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset; vm1's cloud-init disk (lab.sh seed),
# which gives the guest its name and lets ana in with her key; and, after
# virt-install, the wait until vm1 answers ssh (lab.sh wait), which also
# writes its address into host's /etc/hosts.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with QEMU 8.2 and libvirt 10.0, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on MACHINE 'command': what ana typed at her prompt, on host itself or inside
# one of its guests (reached with ssh), and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  if [ "$h" = host ]; then (cd && bash -c "$*") 2>&1 || true
  else ssh "$h" "$*" 2>&1 || true; fi
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() {
  local h=$1; shift
  if [ "$h" = host ]; then sudo bash -c "$*" >/dev/null 2>&1 || true
  else ssh "$h" "sudo bash -c $(printf %q "$*")" >/dev/null 2>&1 || true; fi
}
block() { printf '##### %s\n' "$1"; }

cd ~
lab reset
lab seed vm1

block disk
on host 'cd /var/lib/libvirt/images && sudo qemu-img create -f qcow2 -b lab-base.qcow2 -F qcow2 vm1.qcow2 8G'

block create
on host 'sudo virt-install --name vm1 --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vm1.qcow2,bus=virtio --disk /var/lib/libvirt/images/vm1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole'
on host 'virsh list'
lab wait vm1

block inside
on vm1 'hostname; systemd-detect-virt'
on vm1 'lscpu | grep -E "^(CPU\(s\)|Model name|Hypervisor vendor|Virtualization type)"'
on vm1 'free -h | head -2'
on vm1 'lsblk -d -o NAME,SIZE,TYPE'
on vm1 'ip -br addr'

block outside
on host 'ps -o pid,rss,etime,comm -C qemu-system-x86_64'
on host 'ls -lh /var/lib/libvirt/images/lab-base.qcow2 /var/lib/libvirt/images/vm1.qcow2'
on host 'free -h | head -2'
on host 'nproc'

block power
on host 'virsh shutdown vm1'
sleep 30
on host 'virsh list --all'
on host 'virsh start vm1'
lab wait vm1
on vm1 'uptime -p'

block throw-away
on vm1 'sudo rm -rf --no-preserve-root / 2>/dev/null; ls /'
on host 'virsh destroy vm1 && virsh undefine vm1 && sudo rm /var/lib/libvirt/images/vm1.qcow2'
on host 'virsh list --all'

lab down >/dev/null 2>&1
