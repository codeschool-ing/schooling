#!/usr/bin/env bash
# The terminal session quoted in lesson 3 of operating-systems, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it on a
# newer system and see what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana   # once, on a throwaway machine
#   sudo -u ana -i bash /path/to/captures.sh    # hostname `server`
#
# ONLY LINUX IS CAPTURED HERE, and PowerShell 7 running on that same Linux.
# What only Windows or macOS can print is shown in the lesson as commands with
# no output, and the prose says so where it happens: a transcript nobody ran
# is the one thing this course will not print.
#
# What is STAGED rather than typed, and not shown in the lesson:
# a fresh Ubuntu 24.04 with one user, ana, in the sudo group; download.img, a
# stand-in for a downloaded image, made by seq, with its SHA256SUMS written
# beside it the way a download site publishes one; one byte of it then
# changed by dd; DEBIAN_FRONTEND=noninteractive, kept through sudo, so the
# upgrade asks no questions; and sudo set to ask ana for no password, which a
# real installation does not do.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, booted under systemd-nspawn as the machine `server`,
# with PowerShell 7.6, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
show() {
  printf 'ana@%s:%s$ %s\n' "$(hostname)" "$(pwd | sed "s|^$HOME|~|")" "$*"
  eval "$*" 2>&1 || true
}
tty() {
  printf 'ana@%s:%s$ %s\n' "$(hostname)" "$(pwd | sed "s|^$HOME|~|")" "$*"
  script -qec "$*" /dev/null || true
}
# PowerShell 7 on this same Linux machine, one command per call, as a person
# would type it at the PS prompt.
psh() {
  printf 'PS %s> %s\n' "$(pwd)" "$*"
  pwsh -NoProfile -NoLogo -Command "\$ErrorView='ConciseView'; $* | Out-String -Width 100 -Stream | ForEach-Object { \$_.TrimEnd() }" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
# Lines from stdin, typed one at a time into an interactive bash in a real
# terminal, so job numbers and "Terminated" appear exactly as a person sees them.
session() {
  local cmds; cmds=$(cat)
  printf 'set enable-bracketed-paste off\n' > /tmp/inputrc.$$
  { sleep 0.6; while IFS= read -r l; do printf '%s\n' "$l"; sleep "${PAUSE:-0.8}"; done <<< "$cmds"; printf 'exit\n'; } |
    INPUTRC=/tmp/inputrc.$$ script -qec "env PS1='\\u@\\h:\\w\$ ' HISTFILE=/dev/null bash --norc --noprofile -i" /dev/null | sed '$d' | sed '$d'
  rm -f /tmp/inputrc.$$
}

cd ~ && rm -rf ~/downloads && mkdir ~/downloads && cd ~/downloads
export DEBIAN_FRONTEND=noninteractive
seq 1 200000 > download.img
sha256sum download.img > SHA256SUMS

block checksum
show 'cat SHA256SUMS'
show 'sha256sum -c SHA256SUMS'
printf 'X' | dd of=download.img bs=1 seek=100000 conv=notrunc status=none
show 'sha256sum -c SHA256SUMS'

cd ~
block release
show 'head -5 /etc/os-release'

block update
tty 'sudo apt update'
show 'apt list --upgradable 2>/dev/null | head -6'

block upgrade
show 'sudo apt upgrade -y > upgrade.log 2>&1; tail -3 upgrade.log'
show 'apt list --upgradable 2>/dev/null'

block who
show 'id'
show 'sudo whoami'

block tree
tty 'ls /'
show 'ls /home'

block time
show 'timedatectl'
