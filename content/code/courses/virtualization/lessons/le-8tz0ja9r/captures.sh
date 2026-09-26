#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of virtualization, as a script that produces them.
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
# the lab itself, built by lab.sh reset; vmw1's cloud-init disk (lab.sh seed)
# and the wait until it answers (lab.sh wait); and a VirtualBox machine called
# vmw2, made as lesson 4 made lab1, with ~/lab.vmdk as its disk. VirtualBox is
# installed as lesson 4 describes, and ana's VBoxManage is again the program
# itself rather than Ubuntu's wrapper, which warns about the missing driver.
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
quiet host 'ln -sf /usr/lib/virtualbox/VBoxManage /usr/local/bin/VBoxManage'

block vmdk
on host 'qemu-img convert -O vmdk /var/lib/libvirt/images/lab-base.qcow2 ~/lab.vmdk'
on host 'qemu-img info ~/lab.vmdk | head -5'
on host 'ls -lh /var/lib/libvirt/images/lab-base.qcow2 ~/lab.vmdk'

block split
on host 'mkdir -p ~/split && qemu-img convert -O vmdk -o subformat=twoGbMaxExtentSparse /var/lib/libvirt/images/lab-base.qcow2 ~/split/lab.vmdk && ls -lh ~/split'
on host "tr -d '\\0' < ~/split/lab.vmdk"

block boot
lab seed vmw1
on host 'cd /var/lib/libvirt/images && sudo qemu-img convert -O vmdk lab-base.qcow2 vmw1.vmdk'
on host 'sudo virt-install --name vmw1 --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vmw1.vmdk,format=vmdk,bus=virtio --disk /var/lib/libvirt/images/vmw1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole'
lab wait vmw1
on vmw1 'hostname; lsblk -d -o NAME,SIZE,TYPE /dev/vda'
on host 'virsh domblklist vmw1'

block ovf
quiet host 'runuser -u ana -- VBoxManage createvm --name vmw2 --ostype Ubuntu_64 --register; runuser -u ana -- VBoxManage modifyvm vmw2 --memory 2048 --cpus 2; runuser -u ana -- VBoxManage storagectl vmw2 --name SATA --add sata; runuser -u ana -- VBoxManage storageattach vmw2 --storagectl SATA --port 0 --type hdd --medium /home/ana/lab.vmdk'
on host 'VBoxManage export vmw2 --ovf10 -o ~/vmw2.ova'
on host 'tar tvf ~/vmw2.ova'
on host 'tar xOf ~/vmw2.ova vmw2.ovf | grep -E "<(rasd:ElementName|rasd:VirtualQuantity|vssd:VirtualSystemType)>|<Disk "'

block import
on host 'VBoxManage import ~/vmw2.ova --dry-run'

quiet host 'runuser -u ana -- VBoxManage unregistervm vmw2 --delete; rm -rf "/home/ana/VirtualBox VMs" /home/ana/vmw2.ova /home/ana/lab.vmdk /home/ana/split /usr/local/bin/VBoxManage'
lab down >/dev/null 2>&1
quiet host 'rm -f /var/lib/libvirt/images/vmw1.vmdk'
