#!/usr/bin/env bash
# The lab every command in the virtualisation course ran on.
#
# ONE COMPUTER, CALLED host, RUNS UBUNTU 24.04 WITH QEMU AND LIBVIRT, AND THE
# GUESTS ARE REAL VIRTUAL MACHINES ON IT. Each guest is Ubuntu 24.04 minimal,
# made from one base disk and configured on its first boot by cloud-init: a
# hostname, the user ana, and ana's key from host, so `ssh NAME` works.
#
# The base disk is Ubuntu's minimal cloud image, checked against Ubuntu's
# SHA256SUMS, with five packages added before its first boot and nothing
# else changed: qemu-guest-agent, nginx-light (switched off until a lesson
# starts it), curl, netcat-openbsd and tcpdump. The guests have no internet,
# so they could not have been installed later.
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
#   sudo bash lab.sh up                 libvirt's default network, and a key for ana
#   sudo bash lab.sh vm NAME [NETWORK] [MEMORY_MB] [VCPUS]
#   sudo bash lab.sh seed NAME          the cloud-init disk, for a guest made by hand
#   sudo bash lab.sh wait NAME          until the guest answers ssh, then name it in /etc/hosts
#   sudo bash lab.sh rm NAME
#   sudo bash lab.sh office             a stand-in for the office network, for lesson 11 on
#   sudo bash lab.sh down               every guest, every network but default, and the office
set -euo pipefail

IMAGES=/var/lib/libvirt/images
BASE=$IMAGES/lab-base.qcow2
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

office() {  # the office network: a bridge on host, and one other device on it
  # On your own computer, your real network is this, and a bridged guest joins
  # it through your network card. The computer the lab was recorded on has no
  # network card of its own to lend, so this stands in: a bridge called lan0 on
  # which host is 10.0.0.1, and a device called printer at 10.0.0.50, which
  # answers HTTP, logs who asked, and hands out the office's addresses by DHCP.
  ip link show lan0 >/dev/null 2>&1 && return
  ip link add lan0 type bridge
  ip addr add 10.0.0.1/24 dev lan0
  ip link set lan0 up
  ip netns add printer
  ip link add prn0 type veth peer name prn0-lan
  ip link set prn0-lan master lan0 up
  ip link set prn0 netns printer
  ip -n printer addr add 10.0.0.50/24 dev prn0
  ip -n printer link set prn0 up
  ip -n printer link set lo up
  mkdir -p /var/tmp/office-www
  echo "office printer: ready" > /var/tmp/office-www/index.html
  ip netns exec printer dnsmasq --interface=prn0 --bind-interfaces --port=0 \
    --dhcp-range=10.0.0.100,10.0.0.150,12h --dhcp-option=option:router,10.0.0.1 \
    --dhcp-leasefile=/run/office-dhcp.leases --pid-file=/run/office-dhcp.pid
  ip netns exec printer setsid python3 -m http.server 80 --directory /var/tmp/office-www \
    >/var/log/office-http.log 2>&1 < /dev/null &
  local i
  for i in $(seq 40); do
    ip netns exec printer bash -c ': > /dev/tcp/127.0.0.1/80' 2>/dev/null && break
    sleep 0.25
  done
}

office_down() {
  [ -f /run/office-dhcp.pid ] && kill "$(cat /run/office-dhcp.pid)" 2>/dev/null || true
  ip netns pids printer 2>/dev/null | xargs -r kill 2>/dev/null || true
  ip netns del printer 2>/dev/null || true
  ip link del lan0 2>/dev/null || true
  rm -f /run/office-dhcp.pid /run/office-dhcp.leases
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

vm() {  # vm NAME [NETWORK] [MEMORY_MB] [VCPUS]
  local n=$1 net=${2:-default} mem=${3:-1024} cpus=${4:-2}
  local d=$IMAGES/$n.qcow2 seed=$IMAGES/$n-seed.img
  seed "$n"
  qemu-img create -q -f qcow2 -b "$BASE" -F qcow2 "$d" 8G
  virt-install --name "$n" --virt-type qemu --memory "$mem" --vcpus "$cpus" --import \
    --disk "$d",bus=virtio --disk "$seed",bus=virtio,format=raw --os-variant ubuntu24.04 \
    --network network="$net" --graphics none --noautoconsole >/dev/null 2>&1
  wait_vm "$n"
  # cloud-init has done its job; the seed disk goes, so the guest is only its own disk
  virsh detach-disk "$n" vdb --persistent >/dev/null 2>&1 || true
  rm -f "$seed"
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
