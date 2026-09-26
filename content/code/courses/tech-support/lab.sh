#!/usr/bin/env bash
# The lab every command in the technical support course ran on.
#
# ONE COMPUTER, CALLED host, IS THE TECHNICIAN'S: Ubuntu 24.04 with QEMU and
# libvirt, where ana works. The machines she supports are real virtual
# machines on it, on a network of their own called office, so the faults this
# course breaks on purpose never reach a real network. Each guest is Ubuntu
# 24.04 minimal, made from one base disk and configured on its first boot by
# cloud-init: a hostname, the user ana, and ana's key from host, so `ssh NAME`
# works, as it would for a technician with remote access to the office's
# computers.
#
# The base disk is Ubuntu's minimal cloud image, checked against Ubuntu's
# SHA256SUMS, with twelve packages added before its first boot and nothing
# else changed: qemu-guest-agent, nginx-light (switched off until a lesson
# starts it), curl, netcat-openbsd, tcpdump, dmidecode, lshw, tmux, pciutils,
# usbutils, cups and cups-client. The guests have no internet, so they could
# not have been installed later. It is the virtualisation course's base with
# the last seven added, and it is a separate file so neither course's lab
# changes the other's.
#
# THE BASE DISK IS READ-ONLY (chmod 444): every guest reads from it, and one
# write into it would change every guest at once.
#
# THE COMPUTER THE LAB WAS RECORDED ON IS ITSELF A VIRTUAL MACHINE, WITH NO
# NESTED VIRTUALISATION, so QEMU emulates the guests' processor in software.
# Everything works, only slower. On a computer with VT-x or AMD-V the same
# commands run with --virt-type kvm. The virtualisation course builds a lab
# like this one step by step; this file is the result, used as a tool.
#
#   sudo bash lab.sh up                 the office network, and a key for ana
#   sudo bash lab.sh vm NAME [MEMORY_MB] [VCPUS]    a guest on the office network
#   sudo bash lab.sh wait NAME          until the guest answers ssh, then name it in /etc/hosts
#   sudo bash lab.sh rm NAME
#   sudo bash lab.sh down               every guest, and the office network
#   sudo bash lab.sh reset              down, then up
set -euo pipefail

IMAGES=/var/lib/libvirt/images
BASE=$IMAGES/support-base.qcow2
virsh() { command virsh -q -c qemu:///system "$@"; }

need() {
  local missing=()
  for p in qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients virtinst \
           dnsmasq-base cloud-image-utils dosfstools; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
  [ -f "$BASE" ] || { echo "no base disk at $BASE" >&2; exit 1; }
  chmod 444 "$BASE"
}

up() {
  need
  # the office: an isolated network, 10.30.0.0/24, on which host is 10.30.0.1
  # and libvirt hands out addresses; nothing on it has a route anywhere else
  if ! virsh net-info office >/dev/null 2>&1; then
    local x; x=$(mktemp)
    printf '%s\n' '<network>' '  <name>office</name>' '  <bridge name="virbr3"/>' \
      '  <ip address="10.30.0.1" netmask="255.255.255.0">' '    <dhcp>' \
      '      <range start="10.30.0.10" end="10.30.0.99"/>' '    </dhcp>' '  </ip>' '</network>' > "$x"
    virsh net-define "$x" >/dev/null; rm -f "$x"
  fi
  virsh net-autostart office >/dev/null
  virsh net-list --name | grep -qx office || virsh net-start office >/dev/null
  usermod -aG libvirt ana
  if [ ! -f /home/ana/.ssh/id_ed25519 ]; then
    runuser -u ana -- mkdir -p /home/ana/.ssh
    runuser -u ana -- ssh-keygen -q -t ed25519 -N '' -C ana@host -f /home/ana/.ssh/id_ed25519
  fi
  printf 'Host *\n    StrictHostKeyChecking accept-new\n    LogLevel ERROR\n' > /home/ana/.ssh/config
  chown ana:ana /home/ana/.ssh/config
}

address() {  # address NAME: the guest's IPv4 address, from libvirt's DHCP
  virsh domifaddr "$1" 2>/dev/null | awk '/ipv4/{sub(/\/.*/, "", $4); print $4; exit}' || true
}

seed() {  # seed NAME: the cloud-init disk that names a guest and lets ana in
  local ud; ud=$(mktemp)
  cat > "$ud" <<UD
#cloud-config
hostname: $1
timezone: America/Sao_Paulo
users:
  - name: ana
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys: [ "$(cat /home/ana/.ssh/id_ed25519.pub)" ]
UD
  cloud-localds --filesystem=vfat "$IMAGES/$1-seed.img" "$ud"; rm -f "$ud"
}

wait_vm() {  # wait_vm NAME: until ana can ssh in and cloud-init has finished
  local n=$1 ip='' i
  for i in $(seq 120); do
    ip=$(address "$n")
    [ -n "$ip" ] && runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 "ana@$ip" true 2>/dev/null && break
    ip=''; sleep 5
  done
  [ -n "$ip" ] || { echo "$n did not answer" >&2; exit 1; }
  runuser -u ana -- ssh "ana@$ip" 'cloud-init status --wait' >/dev/null
  sed -i "/ $n\$/d" /etc/hosts; echo "$ip $n" >> /etc/hosts
}

vm() {  # vm NAME [MEMORY_MB] [VCPUS]: a guest on the office network
  local n=$1 mem=${2:-1024} cpus=${3:-2}
  local d=$IMAGES/$n.qcow2 seed=$IMAGES/$n-seed.img
  seed "$n"
  qemu-img create -q -f qcow2 -b "$BASE" -F qcow2 "$d" 8G
  virt-install --name "$n" --virt-type qemu --memory "$mem" --vcpus "$cpus" --import \
    --disk "$d",bus=virtio --disk "$seed",bus=virtio,format=raw --os-variant ubuntu24.04 \
    --network network=office --graphics none --noautoconsole >/dev/null 2>&1
  wait_vm "$n"
  # cloud-init has done its job; the seed disk goes, so the guest is only its own disk
  virsh detach-disk "$n" vdb --persistent >/dev/null 2>&1 || true
  rm -f "$seed"
}

rm_vm() {
  virsh destroy "$1" >/dev/null 2>&1 || true
  virsh undefine "$1" --snapshots-metadata >/dev/null 2>&1 || virsh undefine "$1" >/dev/null 2>&1 || true
  rm -f "$IMAGES/$1.qcow2" "$IMAGES/$1-seed.img" "$IMAGES/$1".*
  sed -i "/ $1\$/d" /etc/hosts
}

down() {
  local n
  for n in $(virsh list --all --name); do rm_vm "$n"; done
  if virsh net-info office >/dev/null 2>&1; then
    virsh net-destroy office >/dev/null 2>&1 || true
    virsh net-undefine office >/dev/null 2>&1 || true
  fi
  # the office's DHCP leases, so an old guest's address is not handed to a
  # new one with the same name, and no lesson reads another's leftovers
  rm -f /var/lib/libvirt/dnsmasq/virbr3.status /home/ana/.ssh/known_hosts
}

case "${1:-}" in
  up) up ;;
  vm) shift; up; vm "$@" ;;
  wait) wait_vm "$2" ;;
  rm) rm_vm "$2" ;;
  down) down ;;
  reset) down; up ;;
  *) echo "usage: lab.sh up|down|reset|vm NAME [MEMORY_MB] [VCPUS]|wait NAME|rm NAME" >&2; exit 2 ;;
esac
