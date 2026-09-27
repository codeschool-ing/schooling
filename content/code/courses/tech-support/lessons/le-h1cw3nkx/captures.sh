#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of tech-support, as a script that produces them.
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
# the lab itself, built by lab.sh reset; the guest pc1, made by lab.sh vm; and
# the user elisa. The lab's guests have no desktop, so the shared screen of
# this lesson is a terminal one, tmux, which has the same three states a
# remote desktop tool has: refused, allowed, and allowed to watch only.
# Elisa's actions are run with sudo -u elisa and are marked so in each line.
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
quiet pc1 'useradd -m -s /bin/bash elisa'

block her-session
on pc1 'sudo -u elisa tmux -S /tmp/help new -d -s help; ls -l /tmp/help'
on pc1 'tmux -S /tmp/help send-keys -t help "hostname" Enter'

block file-is-not-enough
on pc1 'sudo -u elisa chmod 666 /tmp/help; tmux -S /tmp/help send-keys -t help "hostname" Enter'

block consent
on pc1 'sudo -u elisa tmux -S /tmp/help server-access -a ana'
on pc1 'tmux -S /tmp/help send-keys -t help "hostname; whoami" Enter; sleep 1; sudo -u elisa tmux -S /tmp/help capture-pane -p -t help | grep -v "^$"'

block watch-only
on pc1 'sudo -u elisa tmux -S /tmp/help server-access -r ana; tmux -S /tmp/help send-keys -t help "echo typed" Enter'
on pc1 'sudo -u elisa tmux -S /tmp/help server-access -l'

block ending
on pc1 'sudo -u elisa tmux -S /tmp/help server-access -d ana; tmux -S /tmp/help send-keys -t help "hostname" Enter'

block the-record
on pc1 'sudo journalctl -u ssh --no-pager -o cat | grep -m1 Accepted'
on pc1 'sudo journalctl _COMM=sudo --no-pager -o cat | grep "COMMAND=/usr/bin/tmux" | head -2'

lab down >/dev/null 2>&1
