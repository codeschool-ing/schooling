#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset, and the guest vm1, made by lab.sh vm
# exactly as lesson 1 made it by hand.
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
lab vm vm1

block flags
on host 'lscpu | grep -E "^(Vendor ID|Model name|Virtualization|Hypervisor)"'
on host 'grep -m1 "^flags" /proc/cpuinfo | grep -owE "vmx|svm|hypervisor"'
on host 'systemd-detect-virt --vm'

block no-kvm
on host 'ls -l /dev/kvm'
on host 'sudo qemu-system-x86_64 -accel kvm -machine none -display none'
on host 'virsh domcapabilities --virttype kvm'
on host 'virsh capabilities | grep "domain type"'

block guest-flags
on vm1 'lscpu | grep -E "^(Vendor ID|Model name|Virtualization|Hypervisor)"'
on vm1 'grep -m1 "^flags" /proc/cpuinfo | grep -owE "vmx|svm|hypervisor"'

block speed
on host 'time python3 -c "sum(i * i for i in range(3000000))"'
on vm1 'time python3 -c "sum(i * i for i in range(3000000))"'
on host 'time python3 -c "sum(i * i for i in range(3000000))"'
on vm1 'time python3 -c "sum(i * i for i in range(3000000))"'

lab down >/dev/null 2>&1
