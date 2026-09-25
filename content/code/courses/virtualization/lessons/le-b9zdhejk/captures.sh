#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset, and the guest vm1, made by lab.sh vm; a
# minute's wait after breaking vm1, so the clock has moved on before the
# revert, and the wait until vm1 answers ssh again after it; and, between the
# two halves, the deletion of the snapshots the first half made.
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

block take
on vm1 'echo "checked, all fine" > notes.txt; cat notes.txt'
on host 'virsh snapshot-create-as vm1 clean --description "before the change"'
on host 'virsh snapshot-list vm1'
on host 'sudo qemu-img info -U /var/lib/libvirt/images/vm1.qcow2 | sed -n "/^Snapshot list/,/^Format/p" | head -3'
on host 'ls -lsh /var/lib/libvirt/images/vm1.qcow2'

block break
on vm1 'rm notes.txt; sudo mv /usr/bin/ls /usr/bin/ls.gone; ls'
sleep 60

block revert
on host 'virsh snapshot-revert vm1 clean'
for i in $(seq 24); do ssh -o ConnectTimeout=5 vm1 true 2>/dev/null && break; sleep 5; done
on vm1 'cat notes.txt; ls -d /etc; date +%T'
on host 'date +%T'

block tree
on host 'virsh snapshot-create-as vm1 configured >/dev/null && virsh snapshot-create-as vm1 tested >/dev/null && virsh snapshot-list vm1 --tree'
on host 'virsh snapshot-delete vm1 tested && virsh snapshot-list vm1 --tree'

quiet host 'virsh -c qemu:///system snapshot-delete vm1 configured; virsh -c qemu:///system snapshot-delete vm1 clean'

block external
on host 'virsh snapshot-create-as vm1 before-update --disk-only --atomic'
on host 'virsh domblklist vm1'
on vm1 'dd if=/dev/urandom of=big bs=1M count=100 status=none && sync'
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2 vm1.before-update'
on host 'sudo qemu-img info -U --backing-chain /var/lib/libvirt/images/vm1.before-update | grep -E "^(image|backing file):"'

block commit
on host 'virsh blockcommit vm1 vda --active --pivot'
on host 'ls -l /var/lib/libvirt/images/lab-base.qcow2'
on host 'virsh blockcommit vm1 vda --active --pivot --shallow'
on host 'virsh domblklist vm1'
on host 'virsh snapshot-delete vm1 before-update --metadata && sudo rm /var/lib/libvirt/images/vm1.before-update'
on host 'cd /var/lib/libvirt/images && ls -lsh vm1.qcow2'

lab down >/dev/null 2>&1
