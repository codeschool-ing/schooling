#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of tech-support, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guest pc1, made by lab.sh vm; a
# help desk account called tec, with a password set by the script; and the rule
# in /etc/sudoers.d/helpdesk, written by the script and shown in the lesson.
# tec's commands are run from ana's session with sudo -u tec, and are marked so
# in each line. Where sudo asks tec for a password, the script pipes it in
# with sudo -S rather than typing it.
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
quiet pc1 'useradd -m -s /bin/bash tec; echo "tec:lab-only-password" | chpasswd; printf "tec ALL=(root) NOPASSWD: /usr/bin/systemctl restart cups, /usr/sbin/lpadmin\n" > /etc/sudoers.d/helpdesk; chmod 440 /etc/sudoers.d/helpdesk'

block the-rule
on pc1 'sudo cat /etc/sudoers.d/helpdesk'
on pc1 'sudo visudo -cf /etc/sudoers.d/helpdesk'

block what-tec-may
on pc1 'sudo -u tec sudo -l | tail -2'
on pc1 'sudo -u tec sudo systemctl restart cups && echo restarted'

block refused
on pc1 'echo lab-only-password | sudo -u tec sudo -S useradd bruno'

block recorded
on pc1 'sudo journalctl _COMM=sudo --no-pager -o cat | grep "^ *tec :"'

lab down >/dev/null 2>&1
