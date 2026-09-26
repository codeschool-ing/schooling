#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guest vm1, made by lab.sh vm; a
# ten-second wait after each change to the balloon, and forty after asking vm1
# to shut down; and the wait until vm1 answers again (lab.sh wait).
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

block vcpus
on host 'virsh vcpucount vm1'
on host 'virsh vcpuinfo vm1 | grep -E "^(VCPU|CPU|State|CPU time)"'
on vm1 'nproc'

block where-memory-goes
on host 'virsh dommemstat vm1 | grep -E "^(actual|rss)"'
on host 'sudo pmap -x $(pgrep -o qemu-system) | awk "NR > 2 && \$3 > 60000"'
on host 'sudo pmap -x $(pgrep -o qemu-system) | awk "\$5 == \"rwx--\" { n++; rss += \$3 } END { print n, \"areas of translated code,\", rss, \"KiB resident\" }"'

block touch
on host 'sudo pmap -x $(pgrep -o qemu-system) | awk "\$2 == 1048576"'
on vm1 'python3 -c "b = b\"x\" * (400 * 1024 * 1024)"; free -m | head -2'
on host 'sudo pmap -x $(pgrep -o qemu-system) | awk "\$2 == 1048576"'

block balloon
on host 'virsh setmem vm1 524288 --live'
sleep 10
on vm1 'free -m | head -2'
on host 'virsh dommemstat vm1 | grep -E "^(actual|rss)"'
on host 'virsh setmem vm1 1048576 --live'
sleep 10
on vm1 'free -m | head -2'

block virtio
on vm1 'ls /sys/bus/virtio/drivers'

block thin
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2'
on vm1 'dd if=/dev/urandom of=big bs=1M count=300 status=none && sync && ls -lh big'
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2'
on vm1 'rm big && sync && sudo fstrim -v /'
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2'

block change
on host 'virsh setvcpus vm1 1 --config && virsh vcpucount vm1'
on host 'virt-xml vm1 --edit target=vda --disk driver.discard=unmap'
on host 'virsh shutdown vm1'
sleep 40
on host 'virsh start vm1'
lab wait vm1
on vm1 'nproc'

block trim
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2'
on vm1 'sudo fstrim -v /'
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2'

lab down >/dev/null 2>&1
