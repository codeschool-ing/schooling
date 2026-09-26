#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset, and VirtualBox from Ubuntu's own
# packages, installed with virtualbox-source in place of virtualbox-dkms. The
# computer can therefore run VBoxManage and cannot start a guest, which is what
# the block called start shows. After the first block, ana's VBoxManage is the
# program itself rather than Ubuntu's wrapper around it, which checks for the
# driver and prints the same five-line warning before every command.
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

block driver
on host 'VBoxManage --version'
quiet host 'ln -sf /usr/lib/virtualbox/VBoxManage /usr/local/bin/VBoxManage'

block create
on host 'VBoxManage createvm --name lab1 --ostype Ubuntu_64 --register'
on host 'VBoxManage list ostypes | grep -c "^ID:"'

block configure
on host 'VBoxManage modifyvm lab1 --memory 2048 --cpus 2 --graphicscontroller vmsvga --vram 16 --nic1 nat --audio-driver none'

block disk
on host 'cd ~/"VirtualBox VMs"/lab1 && VBoxManage createmedium disk --filename lab1.vdi --size 20480'
on host 'cd ~/"VirtualBox VMs"/lab1 && VBoxManage storagectl lab1 --name SATA --add sata && VBoxManage storageattach lab1 --storagectl SATA --port 0 --type hdd --medium lab1.vdi && VBoxManage storageattach lab1 --storagectl SATA --port 1 --type dvddrive --medium emptydrive'
on host 'VBoxManage showmediuminfo ~/"VirtualBox VMs"/lab1/lab1.vdi | grep -E "^(Format variant|Capacity|Size on disk)"'

block fixed
on host 'cd /tmp && VBoxManage createmedium disk --filename fixed.vdi --size 1024 --variant Fixed'
on host 'ls -lh /tmp/fixed.vdi ~/"VirtualBox VMs"/lab1/lab1.vdi'
quiet host 'runuser -u ana -- VBoxManage closemedium disk /tmp/fixed.vdi --delete'

block settings-file
on host 'ls ~/"VirtualBox VMs"/lab1'
on host 'grep -E "<(Memory|CPU|HardDisk) |<Adapter slot=.0." ~/"VirtualBox VMs"/lab1/lab1.vbox'

block tune
on host 'VBoxManage modifyvm lab1 --paravirtprovider kvm --ioapic on --clipboard-mode bidirectional --boot1 disk --boot2 dvd --boot3 none --boot4 none'
on host 'VBoxManage showvminfo lab1 --machinereadable | grep -E "^(memory|cpus|paravirtprovider|graphicscontroller|vram|nic1|clipboard|boot1|boot2|\"SATA-0-0\")="'

block from-qemu
on host 'cd ~/"VirtualBox VMs"/lab1 && VBoxManage clonemedium /var/lib/libvirt/images/lab-base.qcow2 ubuntu.vdi --format VDI'
on host 'ls -lh /var/lib/libvirt/images/lab-base.qcow2 ~/"VirtualBox VMs"/lab1/ubuntu.vdi'

block start
on host 'VBoxManage startvm lab1 --type headless'

block export
on host 'VBoxManage export lab1 -o ~/lab1.ova'
on host 'tar tvf ~/lab1.ova'

quiet host 'runuser -u ana -- VBoxManage unregistervm lab1 --delete; runuser -u ana -- VBoxManage closemedium disk "/home/ana/VirtualBox VMs/lab1/ubuntu.vdi" --delete; rm -rf "/home/ana/VirtualBox VMs" /home/ana/lab1.ova /usr/local/bin/VBoxManage'
lab down >/dev/null 2>&1
