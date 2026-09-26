#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guest vm1, made by lab.sh vm; and,
# for one block, the guest agent inside vm1 stopped and then started again.
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

block two-kernels
on host 'uname -r; hostname'
on vm1 'uname -r; hostname'
on host 'echo "written on host" > ~/note.txt; ls ~'
on vm1 'ls -A ~; ls ~/note.txt'

block dominfo
on host 'virsh dominfo vm1'

block xml
on host 'virsh dumpxml vm1 | grep -E "<(memory|vcpu|type|emulator|source file|mac address|model type|target dev)"'

block devices
on host 'virsh domblklist vm1'
on host 'virsh domiflist vm1'
on vm1 'ip -br link show enp1s0'

block dmi
on vm1 'cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name'
on vm1 'sudo dmesg | grep -m1 "DMI:"'

block agent
on host 'virsh qemu-agent-command vm1 "{\"execute\":\"guest-get-osinfo\"}" | python3 -m json.tool'
on host 'virsh domifaddr vm1 --source agent'
on host 'virsh domfsinfo vm1'
on host 'virsh domtime vm1; date +%s'

block agent-off
quiet vm1 'systemctl stop qemu-guest-agent'
on host 'virsh domfsinfo vm1'
quiet vm1 'systemctl start qemu-guest-agent'

block reach
on vm1 'ip route'
on host 'ip -br addr show virbr0'
on vm1 'nc -zv -w 3 192.168.122.1 53'

lab down >/dev/null 2>&1
