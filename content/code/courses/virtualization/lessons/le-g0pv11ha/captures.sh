#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of virtualization, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system virtinst \
#        cloud-image-utils libguestfs-tools isc-dhcp-client cpu-checker   # section 03's line
#   sudo -u ana bash /path/to/captures.sh         # NOT -i: the first block needs a session
#                                                 # that started before ana joined libvirt
#
# THIS LESSON BUILDS THE LAB, SO IT IS THE ONE LESSON THAT DOES NOT START FROM
# lab.sh. Every step a student takes is typed here and shown: the check of the
# processor, the base disk from Ubuntu's cloud image, the seed disk by hand, the
# first guest by hand, and newvm.sh, which is TAKEN OUT OF one-command.md rather
# than kept as a copy, so the program the lesson shows is the program this ran.
# lab.sh's `vm` runs the same extracted file for every later lesson.
#
# The computer is called host and runs Ubuntu 24.04. A line that starts with
# ana@host ran on the computer itself, and one that starts with ana@vm1 ran
# inside the guest called vm1, reached with ssh.
#
# THE COMPUTER THE LAB WAS RECORDED ON IS A CONTAINER INSIDE A VIRTUAL MACHINE,
# with no nested virtualisation: there is no /dev/kvm, kvm-ok says so, and
# virt-install falls back to QEMU's imitation by itself. It has no systemd, so
# libvirtd and virtlogd were started by hand before this ran; its libvirt has
# `namespaces = []` in qemu.conf, because a container cannot give QEMU a private
# /dev; and it borrows the outer machine's kernel in /boot and /lib/modules,
# which virt-customize builds its helper from. None of that is a student's step.
#
# What is STAGED rather than typed, and not shown in the lesson: emptying the
# lab before starting; taking ana out of the libvirt group and putting her back,
# which is what the install does to a session that is already open; the wait
# until vm1 has an address and until its first boot has finished; and the
# failures of section 11, each set up and taken down around the command that
# shows it. In `net-in-use`, a bridge called office0 is given the
# default network's range on purpose, which is what a computer that is itself a
# libvirt guest has.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with QEMU 8.2 and libvirt 10.0, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LESSON=${LESSON:-$(cd "$(dirname "$0")" && pwd)}
IMAGES=/var/lib/libvirt/images
URL=https://cloud-images.ubuntu.com/minimal/releases/noble/release

# How ana's commands run. Until she logs in again, in the session she had open
# while the packages went in: her groups as they were, and no LIBVIRT_DEFAULT_URI.
# After, a fresh login, where both have changed.
SESSION=old
run_host() {
  if [ $SESSION = old ]; then (cd && env -u LIBVIRT_DEFAULT_URI bash -c "$1") </dev/null
  else printf '%s\n' "$1" > /tmp/captures-cmd.sh; sudo -u ana -i bash /tmp/captures-cmd.sh </dev/null; fi
}
# on MACHINE 'command': what ana typed at her prompt, on host itself or inside
# one of its guests (reached with ssh), and everything it printed. A command of
# several lines is shown with the shell's continuation prompt.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$(printf '%s' "$*" | sed '2,$s/^/> /')"
  if [ "$h" = host ]; then run_host "$*" 2>&1 || true
  else ssh "$h" "$*" 2>&1 || true; fi
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { sudo bash -c "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
address() {
  virsh -c qemu:///system domifaddr "$1" 2>/dev/null | awk '/ipv4/{sub(/\/.*/, "", $4); print $4; exit}'
}
# until NAME answers ssh with its first boot finished, without trusting its key
# for ana: that happens in front of the reader, in section 06
settle() {
  local i
  for i in $(seq 120); do
    ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "ana@$(address "$1")" 'cloud-init status --wait' >/dev/null 2>&1 && return
    sleep 5
  done
  echo "$1 did not answer" >&2; exit 1
}
empty() {
  local d
  for d in $(virsh -c qemu:///system list --all --name); do
    quiet "virsh -c qemu:///system destroy $d; virsh -c qemu:///system undefine $d"
  done
  quiet "rm -f $IMAGES/*; sed -i '/^192\.168\.122\./d' /etc/hosts"
  rm -rf ~/.ssh ~/*.img ~/*.qcow2 ~/SHA256SUMS ~/user-data ~/newvm.sh
}

# the program section 10 shows, taken out of it
newvm() {
  jq -r '[.parts[].code] | join("\n")' <(awk '/^```schooling-example$/{f=1; next} /^```$/{f=0} f' "$LESSON/one-command.md")
}

if [ "${1:-}" != --session ]; then
  sudo gpasswd -d ana libvirt >/dev/null 2>&1
  exec sudo -u ana bash "$0" --session
fi

cd ~
empty

block check
on host 'sudo kvm-ok'
quiet 'adduser ana libvirt'          # what the install did, behind the open session
on host 'groups; virsh uri; virsh list --all'
SESSION=new
on host 'groups; virsh uri'
on host 'virsh net-list --all'

block base
on host "curl -sSLO $URL/ubuntu-24.04-minimal-cloudimg-amd64.img"
on host "curl -sSLO $URL/SHA256SUMS"
on host 'sha256sum --check --ignore-missing SHA256SUMS' 
on host 'cp ubuntu-24.04-minimal-cloudimg-amd64.img lab-base.qcow2'
on host 'sudo virt-customize -a lab-base.qcow2 --install qemu-guest-agent,nginx-light,curl,netcat-openbsd,tcpdump --run-command "systemctl disable nginx" --truncate /etc/machine-id'
on host 'sudo mv lab-base.qcow2 /var/lib/libvirt/images/ && sudo chmod 444 /var/lib/libvirt/images/lab-base.qcow2'
on host 'sudo ls -lh /var/lib/libvirt/images/'

block seed
on host 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519'
on host 'cat > user-data <<EOF
#cloud-config
hostname: vm1
users:
  - name: $USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys: [ "$(cat ~/.ssh/id_ed25519.pub)" ]
EOF'
on host 'cat user-data'
on host 'sudo cloud-localds /var/lib/libvirt/images/vm1-seed.img user-data'

block disk
on host 'cd /var/lib/libvirt/images && sudo qemu-img create -f qcow2 -b lab-base.qcow2 -F qcow2 vm1.qcow2 8G'

block create
on host 'sudo virt-install --name vm1 --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vm1.qcow2,bus=virtio --disk /var/lib/libvirt/images/vm1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole'
on host 'virsh list'
settle vm1

block name
on host 'virsh domifaddr vm1'
ip=$(address vm1)
on host "echo \"$ip vm1\" | sudo tee -a /etc/hosts"
printf 'ana@host:~$ ssh vm1 hostname\n'
(sleep 5; echo yes; sleep 5) | script -qfc 'sudo -u ana -i ssh vm1 hostname' /dev/null | tr -d '\r'

block inside
on vm1 'hostname; systemd-detect-virt'
on vm1 'lscpu | grep -E "^(CPU\(s\)|Model name|Hypervisor vendor|Virtualization type)"'
on vm1 'free -h | head -2'
on vm1 'lsblk -d -o NAME,SIZE,TYPE'
on vm1 'ip -br addr'

block outside
on host 'ps -o pid,rss,etime,comm -C qemu-system-x86_64'
on host 'ls -lh /var/lib/libvirt/images/lab-base.qcow2 /var/lib/libvirt/images/vm1.qcow2'
on host 'free -h | head -2'
on host 'nproc'

block power
on host 'virsh shutdown vm1'
sleep 30
on host 'virsh list --all'
on host 'virsh start vm1'
settle vm1
on vm1 'uptime -p'

block throw-away
on vm1 'sudo rm -rf --no-preserve-root / 2>/dev/null; ls /'
on host 'virsh destroy vm1 && virsh undefine vm1 && sudo rm /var/lib/libvirt/images/vm1.qcow2'
on host 'virsh list --all'

block newvm
newvm > ~/newvm.sh
on host 'time bash newvm.sh vm1'
on host 'ssh vm1 hostname; tail -1 /etc/hosts'

# ---- section 11: each failure set up, shown, and taken down ---------------

block no-kvm
on host 'ls -l /dev/kvm'

block home
quiet "qemu-img create -q -f qcow2 -b $IMAGES/lab-base.qcow2 -F qcow2 /home/ana/vm2.qcow2 8G; chown ana:ana /home/ana/vm2.qcow2"
on host 'ls -ld ~ && sudo virt-install --name vm2 --memory 1024 --vcpus 2 --import --disk ~/vm2.qcow2,bus=virtio --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole'
quiet "virsh -c qemu:///system undefine vm2; rm -f /home/ana/vm2.qcow2"

block net-in-use
quiet 'virsh -c qemu:///system net-destroy default; ip link add office0 type bridge; ip addr add 192.168.122.50/24 dev office0; ip link set office0 up'
on host 'virsh net-start default'
quiet 'ip link del office0; virsh -c qemu:///system net-start default'

block no-dhcp
quiet 'DEBIAN_FRONTEND=noninteractive apt-get remove -y isc-dhcp-client'
on host 'cp ubuntu-24.04-minimal-cloudimg-amd64.img try.qcow2'
on host 'sudo virt-customize -a try.qcow2 --install qemu-guest-agent,nginx-light,curl,netcat-openbsd,tcpdump --run-command "systemctl disable nginx" --truncate /etc/machine-id'
quiet 'DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-client'
rm -f ~/try.qcow2

block no-header
quiet "printf 'hostname: vm2\nusers:\n  - name: ana\n    ssh_authorized_keys: [ \"%s\" ]\n' \"\$(cat /home/ana/.ssh/id_ed25519.pub)\" > /home/ana/user-data; chown ana:ana /home/ana/user-data
  cloud-localds $IMAGES/vm2-seed.img /home/ana/user-data
  qemu-img create -q -f qcow2 -b $IMAGES/lab-base.qcow2 -F qcow2 $IMAGES/vm2.qcow2 8G
  virt-install --name vm2 --memory 1024 --vcpus 2 --import --disk $IMAGES/vm2.qcow2,bus=virtio --disk $IMAGES/vm2-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole"
for i in $(seq 120); do [ -n "$(address vm2)" ] && break; sleep 5; done
sleep 180
quiet "echo '$(address vm2) vm2' >> /etc/hosts"
ssh-keyscan -t ed25519 "$(address vm2)" 2>/dev/null | sed "s/^[^ ]*/vm2/" >> ~/.ssh/known_hosts
on host 'head -2 user-data'
on host 'ssh vm2 hostname'
on host 'virsh domifaddr vm2 --source agent'

empty
