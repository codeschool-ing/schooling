#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of tech-support, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guests pc1, pc2 and srv1, made by
# lab.sh vm, srv1 with 1536 MiB of memory and the others with 1024; and
# inventory.sh, written into ana's home and copied to each guest's /tmp.
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
lab vm pc1 >/dev/null 2>&1
lab vm pc2 >/dev/null 2>&1
lab vm srv1 1536 >/dev/null 2>&1
cat > ~/inventory.sh <<'INV'
#!/usr/bin/env bash
# inventory.sh: one CSV line describing this computer, for the asset register.
maker=$(sudo dmidecode -s system-manufacturer)
model=$(sudo dmidecode -s system-product-name)
serial=$(sudo dmidecode -s system-serial-number)
cpu=$(lscpu | awk -F': +' '/^Model name/ {print $2}')
mem=$(free -m | awk '/^Mem:/ {print $2 " MiB"}')
root=$(df -h --output=size / | tail -n 1 | tr -d ' ')
mac=$(ip -br link | awk '$1 != "lo" {print $3; exit}')
. /etc/os-release
printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
  "$(hostname)" "$maker" "$model" "$serial" "$cpu" "$mem" "$root" "$mac" "$VERSION_ID"
INV
for m in pc1 pc2 srv1; do scp -q ~/inventory.sh $m:/tmp/inventory.sh; done

block one
on pc1 'sudo dmidecode -t system | grep -E "Manufacturer|Product Name|Serial Number|UUID"'
on pc1 'bash /tmp/inventory.sh'

block register
on host 'echo "name,maker,model,serial,cpu,memory,root fs,mac,os" > assets.csv; for m in pc1 pc2 srv1; do ssh $m bash /tmp/inventory.sh >> assets.csv; done; cat assets.csv'

block parts
on pc1 'sudo lshw -short -class disk -class network -class memory 2>/dev/null'

lab down >/dev/null 2>&1
rm -f ~/inventory.sh ~/assets.csv
