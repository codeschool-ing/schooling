#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset, and the guest vm1, made by lab.sh vm;
# thirty seconds after each shutdown; the wait until vm1 answers ssh and vm2's
# guest agent answers the host; vm2 removed (lab.sh rm) after its block; the
# cloud-init disks of web1 and web2 (lab.sh seed), and the wait until each
# answers (lab.sh wait).
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

block full-clone
on host 'virsh shutdown vm1'
sleep 30
on host 'sudo virt-clone --original vm1 --name vm2 --auto-clone'
on host 'sudo ls -lsh /var/lib/libvirt/images/vm1.qcow2 /var/lib/libvirt/images/vm2.qcow2'
on host 'virsh domiflist vm1; virsh domiflist vm2'
on host 'virsh start vm1 && virsh start vm2'
lab wait vm1
for i in $(seq 60); do virsh -c qemu:///system qemu-agent-command vm2 '{"execute":"guest-ping"}' >/dev/null 2>&1 && break; sleep 5; done
sleep 20

block no-network
on host 'virsh domhostname vm2 --source agent'
on host 'virsh domifaddr vm2 --source agent'
on vm1 'sudo cat /etc/netplan/50-cloud-init.yaml'

lab rm vm2 >/dev/null 2>&1

block seal
on vm1 'cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2'
on vm1 'sudo cloud-init clean --logs --seed --machine-id --configs all && sudo rm -f /etc/ssh/ssh_host_* && cat /etc/machine-id && ls /etc/ssh/ssh_host_* 2>&1'
on host 'virsh shutdown vm1'
sleep 30
on host 'virsh undefine vm1 && cd /var/lib/libvirt/images && sudo mv vm1.qcow2 template.qcow2 && sudo chmod 444 template.qcow2 && ls -l template.qcow2'

block linked
lab seed web1 >/dev/null 2>&1
lab seed web2 >/dev/null 2>&1
on host 'cd /var/lib/libvirt/images && for n in web1 web2; do sudo qemu-img create -q -f qcow2 -b template.qcow2 -F qcow2 $n.qcow2 8G; done && ls -lsh template.qcow2 web1.qcow2 web2.qcow2'
on host 'sudo qemu-img info --backing-chain /var/lib/libvirt/images/web1.qcow2 | grep "^image:"'
on host 'for n in web1 web2; do sudo virt-install --name $n --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/$n.qcow2,bus=virtio --disk /var/lib/libvirt/images/$n-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole >/dev/null 2>&1; done; virsh list'
lab wait web1
lab wait web2

block different
on web1 'hostname; cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2; ip -br addr show enp1s0'
on web2 'hostname; cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2; ip -br addr show enp1s0'

lab down >/dev/null 2>&1
quiet host 'rm -f /var/lib/libvirt/images/template.qcow2'
