#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of virtualization, as a script that produces them.
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
# two folders on host, /srv/share and /srv/docs, with one file each, owned by
# ana; forty seconds after asking vm1 to shut down, and the wait until it
# answers again (lab.sh wait); and a VirtualBox machine called lab1, registered
# as in lesson 4, with ana's VBoxManage again the program behind Ubuntu's
# wrapper.
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
quiet host 'rm -rf /srv/share /srv/docs; mkdir -p /srv/share /srv/docs; echo "written on host" > /srv/share/from-host.txt; echo "how to reset the printer" > /srv/docs/manual.txt; chown -R ana:ana /srv/share /srv/docs'

block attach
on host 'ls -l /srv/share /srv/docs'
on host 'virt-xml vm1 --add-device --filesystem source=/srv/share,target=share,accessmode=mapped'
on host 'virt-xml vm1 --add-device --filesystem source=/srv/docs,target=docs,accessmode=mapped,readonly=on'
on host 'virsh shutdown vm1'
sleep 40
on host 'virsh start vm1'
lab wait vm1
on host 'virsh dumpxml vm1 | grep -A5 "<filesystem"'

block mount
on vm1 'sudo mkdir -p /mnt/share /mnt/docs && sudo mount -t 9p -o trans=virtio,version=9p2000.L share /mnt/share && sudo mount -t 9p -o trans=virtio,version=9p2000.L docs /mnt/docs && ls -l /mnt/share /mnt/docs'
on vm1 'cat /mnt/share/from-host.txt /mnt/docs/manual.txt'

block write
on vm1 'echo "written in vm1" > /mnt/share/from-guest.txt'
on host 'ls -ld /srv/share; ps -o user= -C qemu-system-x86_64'
on host 'sudo chgrp kvm /srv/share && sudo chmod g+w /srv/share'
on vm1 'echo "written in vm1" > /mnt/share/from-guest.txt && ls -l /mnt/share'
on host 'ls -l /srv/share && cat /srv/share/from-guest.txt'
on vm1 'echo "a note" > /mnt/docs/note.txt'

block fstab
on vm1 'echo "share /mnt/share 9p trans=virtio,version=9p2000.L,nofail 0 0" | sudo tee -a /etc/fstab'
on vm1 'sudo umount /mnt/share && sudo mount -a && findmnt /mnt/share'

quiet host 'ln -sf /usr/lib/virtualbox/VBoxManage /usr/local/bin/VBoxManage; runuser -u ana -- VBoxManage createvm --name lab1 --ostype Ubuntu_64 --register'

block vbox
on host 'VBoxManage sharedfolder add lab1 --name docs --hostpath /srv/docs --readonly --automount'
on host 'VBoxManage modifyvm lab1 --clipboard-mode bidirectional --drag-and-drop hosttoguest'
on host 'VBoxManage showvminfo lab1 --machinereadable | grep -E "^(SharedFolder|clipboard|draganddrop)"'

quiet host 'runuser -u ana -- VBoxManage unregistervm lab1 --delete; rm -rf "/home/ana/VirtualBox VMs" /usr/local/bin/VBoxManage'
lab down >/dev/null 2>&1
quiet host 'rm -rf /srv/share /srv/docs'
