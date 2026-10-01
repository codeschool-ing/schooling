#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo apt install mininet               # plus lab.sh's own packages
#   sudo useradd -m -s /bin/bash ana       # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh    # the lab, beside course.json
#   sudo bash captures.sh
#
# Two things run here. Mininet 2.3.0, from Ubuntu's own package, run on the
# machine itself (the prompt ana@lab) with Linux bridges as its switches and no
# OpenFlow controller, so it needs nothing but the kernel. Then lab.sh's
# "office" scenario, to show what this course's own lab is made of.
#
# Packet Tracer, GNS3 and EVE-NG were NOT run for this lesson: each needs a
# graphical install and, for anything beyond a toy, images of commercial
# router software that are licensed per user. The lesson says what they are
# and never prints output from them.
#
# What is STAGED rather than typed, and not shown in the lesson: `mn -c`,
# Mininet's own clean-up, run before each Mininet command so a run never
# meets what the last one left behind; and the office lab, built by
# `lab.sh up office`.
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() { local h=$1; shift; printf 'ana@%s:~$ %s\n' "$h" "$*"; lab exec "$h" ana "$*" 2>&1 || true; }
# root HOST 'command': the same at a root prompt, on a device being configured.
root() { local h=$1; shift; printf 'root@%s:~# %s\n' "$h" "$*"; lab exec "$h" root "$*" 2>&1 || true; }
# quiet HOST 'command': the lab's own housekeeping, run as root and not shown.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while another does something, the way
# a second terminal would be: its prompt and output are printed when it ends.
bgon() {  # bgon USER HOST 'command'
  local p='$'; [ "$1" = root ] && p='#'
  printf '%s@%s:~%s %s\n' "$1" "$2" "$p" "$3" > /tmp/bg.out
  lab exec "$2" "$1" "$3" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep 2
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }
# here 'command': typed on the machine itself, outside any lab device
here() { printf 'ana@lab:~$ %s\n' "$*"; runuser -u ana -- env -i HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ=$TZ LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $*" 2>&1 || true; }

lab down

block mininet-pingall
mn -c >/dev/null 2>&1
here 'sudo mn --switch lxbr --controller none --topo linear,3 --test pingall'

block mininet-cli
mn -c >/dev/null 2>&1
here 'printf "net\nh1 ip -br addr\nh1 ping -c 2 h3\nexit\n" | sudo mn --switch lxbr --controller none --topo linear,3'

block this-lab
lab up office
here 'ip netns list'
here 'sudo ip -n sw1 -br link'
here 'sudo ip netns exec pc1 ip -br addr'
