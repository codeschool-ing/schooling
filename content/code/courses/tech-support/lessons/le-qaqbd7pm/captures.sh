#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of tech-support, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guests srv1, pc1 and pc2, made by
# lab.sh vm on the office network; nginx started on srv1 with a one-line page;
# the line '<srv1's address> intranet' added to pc2's /etc/hosts, as the
# office's standard entry; and THE FAULT: pc1 got '10.30.0.200 intranet'
# instead, standing for an entry never updated when the intranet moved to
# another server. Nothing answers at 10.30.0.200.
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
lab vm srv1 >/dev/null 2>&1
lab vm pc1 >/dev/null 2>&1
lab vm pc2 >/dev/null 2>&1
srv=$(awk '$2 == "srv1" {print $1}' /etc/hosts)
quiet srv1 'systemctl enable --now nginx; echo "intranet: welcome" > /var/www/html/index.html'
quiet pc2 "echo '$srv intranet' >> /etc/hosts"
quiet pc1 "echo '10.30.0.200 intranet' >> /etc/hosts"

block reproduce
on pc1 'date "+%H:%M"; curl -sS -m 10 http://intranet/'
on pc1 'curl -sS -m 10 http://intranet/'

block isolate
on pc2 'curl -sS -m 10 http://intranet/'
on pc1 'getent hosts intranet'
on pc2 'getent hosts intranet'
on pc1 "curl -sS -m 10 http://$srv/"

block test
on pc1 'grep -n intranet /etc/hosts'
on pc1 "sudo sed -i 's/^10.30.0.200 intranet$/$srv intranet/' /etc/hosts && grep -n intranet /etc/hosts"

block confirm
on pc1 'getent hosts intranet; curl -sS -m 10 http://intranet/'

lab down >/dev/null 2>&1
