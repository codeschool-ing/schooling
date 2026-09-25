#!/usr/bin/env bash
# The terminal session quoted in lesson 11 of operating-systems, as a script that produces it.
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
# the Ubuntu 24.04 server from lesson 3, updated, with one user, ana, in the
# sudo group; tree and man-db removed first, so each run starts without them,
# and tree removed again at the end; apt set to print plain progress lines
# (Dpkg::Progress-Fancy false) instead of a bar drawn at the bottom of the
# screen; DEBIAN_FRONTEND=noninteractive; and sudo set to ask ana for no
# password, which a real installation does not do.
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

cd ~
export DEBIAN_FRONTEND=noninteractive
echo 'Dpkg::Progress-Fancy "false";' | sudo tee /etc/apt/apt.conf.d/99capture-plain >/dev/null
sudo apt-get purge -y -qq tree man-db >/dev/null 2>&1
sudo apt-get autoremove -y -qq >/dev/null 2>&1

block missing
session <<'S'
tree
S

block search
tty "apt search --names-only '^tree\$'"
show "apt-cache show tree | grep -E '^(Package|Version|Section|Installed-Size|Depends|Description-en)'"

block install
tty 'sudo apt install -y tree'
show 'which tree'
show 'dpkg -L tree | grep bin/'
show 'tree -L 1 /etc/apt'

block deps
tty 'sudo apt install -y man-db'
show 'man -f ls'

block remove
tty 'sudo apt remove -y man-db'
show 'dpkg -l man-db | tail -1'
tty 'sudo apt autoremove -y'
tty 'sudo apt purge -y man-db'
show 'dpkg -l man-db 2>&1 | tail -1'

block history
show "grep -E '^(Commandline|Requested-By)' /var/log/apt/history.log | tail -4"
show "dpkg -l | grep -c '^ii'"

sudo apt-get purge -y -qq tree >/dev/null 2>&1
