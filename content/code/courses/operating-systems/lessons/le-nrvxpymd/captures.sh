#!/usr/bin/env bash
# The terminal session quoted in lesson 10 of operating-systems, as a script that produces it.
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
# the Ubuntu 24.04 server from lesson 3, with one user, ana, in the sudo group;
# a second user, carla, created, given a throwaway password and removed again
# within the session, and deleted first in case an earlier run left her; the
# password typed at passwd and su is in this script, and the terminal does not
# echo it; and sudo set to ask ana for no password, which a real installation
# does not do. The NOPASSWD line in sudo -l is that setting.
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
sudo userdel -r carla >/dev/null 2>&1

block passwd-file
show 'getent passwd root ana www-data nobody'
show "awk -F: '\$3 < 1000' /etc/passwd | wc -l"
show "awk -F: '\$3 >= 1000 && \$3 < 65534' /etc/passwd"

block groups
show 'groups'
show 'getent group sudo'

block create
show 'sudo useradd -m -s /bin/bash -c "Carla Souza" carla'
show 'getent passwd carla'
show 'sudo passwd -S carla'
show 'ls -A /home/carla'
show 'sudo ls -A /home/carla'

block password
PAUSE=1.2 session <<'S'
sudo passwd carla
temporary-Password-4291
temporary-Password-4291
sudo passwd -S carla
S

block su
PAUSE=1.5 session <<'S'
su - carla
temporary-Password-4291
whoami
exit
S

block expire
show 'sudo passwd -e carla'
show 'sudo chage -l carla | head -3'

block lock
show 'sudo usermod -L carla'
show 'sudo passwd -S carla'
show 'sudo usermod -U carla'

block root
show 'sudo passwd -S root'
show 'sudo passwd -S ana'

block sudo-l
show 'sudo -l'

block sudo-log
show "sudo journalctl _COMM=sudo --no-pager -o cat | grep COMMAND | tail -3"

block remove
show 'sudo userdel -r carla'
show 'getent passwd carla || echo "no such user"'
