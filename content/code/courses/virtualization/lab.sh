#!/usr/bin/env bash
# The lab every command in the virtualisation course ran on.
#
# ONE COMPUTER, CALLED host, RUNS UBUNTU 24.04 WITH QEMU AND LIBVIRT, AND THE
# GUESTS ARE REAL VIRTUAL MACHINES ON IT. Each guest is Ubuntu 24.04 minimal,
# made from one base disk and configured on its first boot by cloud-init: a
# hostname, the user ana, and ana's key from host, so `ssh NAME` works.
#
# The base disk is Ubuntu's minimal cloud image, checked against Ubuntu's
# SHA256SUMS, with five packages added by virt-customize before its first
# boot and its machine-id emptied again: qemu-guest-agent, nginx-light
# (switched off until a lesson starts it), curl, netcat-openbsd and tcpdump.
# Guests on an isolated network have no internet, so they could not be
# installed later.
#
# THE BASE DISK IS READ-ONLY (chmod 444), and that is not tidiness. Every guest
# reads from it, so one write into it changes every guest at once, and there
# is a command that does exactly that by default: lesson 9 shows it failing
# against this file, which is the only reason it fails.
#
# THE COMPUTER THE LAB WAS RECORDED ON IS ITSELF A VIRTUAL MACHINE, WITH NO
# NESTED VIRTUALISATION: there is no /dev/kvm, and QEMU emulates the guests'
# processor in software. Everything works; it is slower, and lesson 2 measures
# by how much. On a computer with VT-x or AMD-V the same commands run with
# --virt-type kvm.
#
# THE BASE DISK IS MADE BY LESSON 1'S captures.sh, exactly as section 04 of that
# lesson shows a student, and this script refuses to run without it.
#
# `vm` and `office` RUN THE STUDENT'S OWN PROGRAMS, taken out of the lessons that
# show them: newvm.sh from lesson 1's one-command.md, and office.sh from lesson
# 11's an-office-and-two-networks.md. A capture made through this script ran the
# program the reader was given, never a copy of it that could drift.
#
#   sudo bash lab.sh up                 libvirt's default network, and a key for ana
#   sudo bash lab.sh vm NAME [NETWORK] [MEMORY_MB] [VCPUS]    newvm.sh, as ana
#   sudo bash lab.sh seed NAME          the cloud-init disk, for a guest made by hand
#   sudo bash lab.sh wait NAME          until the guest answers ssh, then name it in /etc/hosts
#   sudo bash lab.sh rm NAME
#   sudo bash lab.sh office             office.sh, the office network, for lesson 11 on
#   sudo bash lab.sh down               every guest, every network but default, and the office
set -euo pipefail

IMAGES=/var/lib/libvirt/images
HERE=$(cd "$(dirname "$0")" && pwd)
LESSONS=${LESSONS:-$HERE/lessons}
# a program a lesson shows in a schooling-example block, as the copy button gives it
shown() {
  awk '/^```schooling-example$/{f=1; next} /^```$/{f=0} f' "$1" | jq -r '[.parts[].code] | join("\n")'
}
BASE=$IMAGES/lab-base.qcow2
virsh() { command virsh -q -c qemu:///system "$@"; }

need() {
  local missing=()
  for p in qemu-system-x86 qemu-utils libvirt-daemon-system virtinst cloud-image-utils jq; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
  [ -f "$BASE" ] || { echo "no base disk at $BASE: run lesson 1's captures.sh first" >&2; exit 1; }
  chmod 444 "$BASE"
}

up() {
  need
  virsh net-info default >/dev/null 2>&1 || virsh net-define /usr/share/libvirt/networks/default.xml >/dev/null
  virsh net-autostart default >/dev/null
  virsh net-list --name | grep -qx default || virsh net-start default >/dev/null
  # the libvirt group lets ana run virsh without sudo, against the system's
  # guests rather than a private set of her own; it counts from her next login
  usermod -aG libvirt ana
  if [ ! -f /home/ana/.ssh/id_ed25519 ]; then
    runuser -u ana -- mkdir -p /home/ana/.ssh
    runuser -u ana -- ssh-keygen -q -t ed25519 -N '' -C ana@host -f /home/ana/.ssh/id_ed25519
  fi
  printf 'Host *\n    StrictHostKeyChecking accept-new\n    LogLevel ERROR\n' > /home/ana/.ssh/config
  chown ana:ana /home/ana/.ssh/config
}

address() {  # address NAME: the guest's IPv4 address, from libvirt's DHCP or from the agent
  local a
  a=$(virsh domifaddr "$1" 2>/dev/null | awk '/ipv4/{sub(/\/.*/, "", $4); print $4; exit}') || true
  # a guest on a bridged network gets its address from the office's DHCP, which
  # libvirt never sees, so the guest agent is asked instead
  [ -n "$a" ] || a=$(virsh domifaddr "$1" --source agent 2>/dev/null |
                     awk '/ipv4/ && $4 !~ /^127\./ {sub(/\/.*/, "", $4); print $4; exit}') || true
  echo "$a"
}

office() {  # the office network: office.sh, as lesson 11 shows it
  shown "$LESSONS/le-v5g6z9yr/an-office-and-two-networks.md" > /var/tmp/office.sh
  bash /var/tmp/office.sh >/dev/null
}

office_down() {
  [ -f /var/tmp/office.sh ] && bash /var/tmp/office.sh down
  rm -f /run/office-dhcp.pid /run/office-dhcp.leases /var/tmp/office.sh
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
  cloud-localds "$IMAGES/$1-seed.img" "$ud"; rm -f "$ud"
}

wait_vm() {  # vm NAME [NETWORK] [MEMORY_MB] [VCPUS]: newvm.sh, as lesson 1 shows it
  shown "$LESSONS/le-g0pv11ha/one-command.md" > /home/ana/newvm.sh
  chown ana:ana /home/ana/newvm.sh
  runuser -u ana -- bash -c 'cd && bash newvm.sh "$@"' newvm "$@" >/dev/null
}

rm_vm() {
  virsh destroy "$1" >/dev/null 2>&1 || true
  virsh undefine "$1" --snapshots-metadata >/dev/null 2>&1 || virsh undefine "$1" >/dev/null 2>&1 || true
  # the disk, the seed, and any external snapshot layered on the disk (NAME.something)
  rm -f "$IMAGES/$1.qcow2" "$IMAGES/$1-seed.img" "$IMAGES/$1".*
  sed -i "/ $1\$/d" /etc/hosts
}

down() {
  local n
  for n in $(virsh list --all --name); do rm_vm "$n"; done
  for n in $(virsh net-list --all --name); do
    [ "$n" = default ] && continue
    virsh net-destroy "$n" >/dev/null 2>&1 || true; virsh net-undefine "$n" >/dev/null 2>&1 || true
  done
  rm -f /home/ana/.ssh/known_hosts
  office_down
  # the default network's DHCP leases, so an old guest's address is not handed
  # to a new one with the same name, and no lesson reads another's leftovers
  if virsh net-info default >/dev/null 2>&1; then
    virsh net-destroy default >/dev/null 2>&1 || true
    rm -f /var/lib/libvirt/dnsmasq/virbr0.status
  fi
}

case "${1:-}" in
  up) up ;;
  vm) shift; up; vm "$@" ;;
  seed) up; seed "$2" ;;
  wait) wait_vm "$2" ;;
  rm) rm_vm "$2" ;;
  down) down ;;
  office) office ;;
  reset) down; up ;;
  *) echo "usage: lab.sh up|down|reset|office|vm NAME [NETWORK] [MEMORY_MB] [VCPUS]|rm NAME" >&2; exit 2 ;;
esac
