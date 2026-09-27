#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of tech-support, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guest pc1, made by lab.sh vm; the
# user daniel, with september.csv in his home; the office's shared folder at
# /srv/shared, which on pc1 is a 64 MiB disk image mounted there, standing in
# for a second disk; the folders reports (daniel's) and logs in it; and THE
# FAULT: a log, logs/export.log, written until it filled the disk, the same
# line repeated as a program retrying something forever would write it.
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
quiet pc1 'useradd -m -s /bin/bash daniel; truncate -s 64M /var/lib/shared.img; mkfs.ext4 -q -L shared /var/lib/shared.img; mkdir -p /srv/shared; mount -o loop /var/lib/shared.img /srv/shared; mkdir -p /srv/shared/reports /srv/shared/logs; chown daniel /srv/shared/reports; printf "region,total\nsouth,1200\nnorth,980\n" > /home/daniel/september.csv; chown daniel /home/daniel/september.csv; yes "2026-09-26 export: retrying connection to the sales database" | head -c 70M > /srv/shared/logs/export.log 2>/dev/null; true'

block symptom
on pc1 'sudo -u daniel cp /home/daniel/september.csv /srv/shared/reports/'

block user-and-application
on pc1 'sudo -u daniel ls -l /home/daniel/september.csv; ls -ld /srv/shared/reports'
on pc1 'sudo -u daniel bash -c "echo test > /srv/shared/reports/test.txt"'

block system
on pc1 'df -h /srv/shared'
on pc1 'sudo du -sh /srv/shared/*'
on pc1 'sudo tail -n 2 /srv/shared/logs/export.log; echo'

block network-and-hardware
on pc1 'findmnt -o TARGET,SOURCE,FSTYPE /srv/shared'
on pc1 'sudo dmesg --level=err,crit,alert,emerg | wc -l'

block fix
on pc1 'sudo tail -n 1000 /srv/shared/logs/export.log | sudo tee /srv/shared/logs/export.log.keep >/dev/null && sudo mv /srv/shared/logs/export.log.keep /srv/shared/logs/export.log && df -h /srv/shared'
on pc1 'sudo tail -n 1000 /srv/shared/logs/export.log > /tmp/export.log.keep && sudo cp /tmp/export.log.keep /srv/shared/logs/export.log && df -h /srv/shared'
on pc1 'sudo -u daniel cp /home/daniel/september.csv /srv/shared/reports/ && ls -l /srv/shared/reports/'

lab down >/dev/null 2>&1
