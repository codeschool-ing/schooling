#!/usr/bin/env bash
# The terminal session quoted in lesson 1 of operating-systems, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it on a
# newer system and see what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana   # once, on a throwaway machine
#   sudo -u ana -i bash /path/to/captures.sh    # hostname `server`
#   sudo -u ana -i bash /path/to/captures.sh iso   # hostname `laptop`, with the
#                                  # server ISO and its SHA256SUMS in ~/Downloads
#
# THE BLOCKS THE STUDENT TYPES TO SET A SECTION UP ARE READ OUT OF THE LESSON.
# stage() takes the sh fence of a section whose first line is the one given and
# runs it as written, so what the lesson shows and what made these transcripts
# cannot drift apart; a fence that is not there stops the script.
#
# ONLY LINUX IS CAPTURED HERE, and PowerShell 7 running on that same Linux.
# What only Windows or macOS can print is shown in the lesson as commands with
# no output, and the prose says so where it happens: a transcript nobody ran
# is the one thing this course will not print.
#
# What is STAGED rather than typed, and not shown in the lesson:
# `%1` and `%2` are the two sleeps started a moment before. The folder ~/office
# and its one file are the fence at the top of the section on processes, run
# from the lesson by stage(). For the setup sections: the machine is the
# Ubuntu Server 24.04 the lesson builds, with one user, ana, in the sudo group;
# PowerShell and Microsoft's repository purged first, so each run installs
# them; the line 127.0.1.1 server taken out of /etc/hosts before the block
# that shows what that does, and put back by the block itself; the machine
# reaches the internet through a proxy set in its environment; and sudo set to
# ask ana for no password, which a real installation does not do.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, booted under systemd-nspawn as the machine `server`,
# with PowerShell 7.6, TZ=America/Sao_Paulo. The setup sections were recorded
# later, on 7 October 2026, on Ubuntu 24.04.5 under systemd-nspawn without
# booting it, which is all a package install and sudo need.

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
here=$(cd "$(dirname "$0")" && pwd)
stage() {
  local fence
  fence=$(awk -v first="$2" '
    /^```sh$/ { inside = 1; n = 0; next }
    /^```$/ && inside { if (keep) exit; inside = 0; next }
    inside { n++; if (n == 1 && $0 == first) keep = 1; if (keep) print }
  ' "$here/$1")
  [ -n "$fence" ] || { echo "captures.sh: no sh fence starting \"$2\" in $1" >&2; exit 1; }
  eval "$fence"
}
# Lines from stdin, typed one at a time into an interactive bash in a real
# terminal, so job numbers and "Terminated" appear exactly as a person sees them.
session() {
  local cmds; cmds=$(cat)
  printf 'set enable-bracketed-paste off\n' > /tmp/inputrc.$$
  { sleep 0.6; while IFS= read -r l; do printf '%s\n' "$l"; sleep "${PAUSE:-0.8}"; done <<< "$cmds"; printf 'exit\n'; } |
    INPUTRC=/tmp/inputrc.$$ script -qec "env PS1='\\u@\\h:\\w\$ ' HISTFILE=/dev/null bash --norc --noprofile -i" /dev/null | sed '$d' | sed '$d'
  rm -f /tmp/inputrc.$$
}

if [ "${1:-}" = iso ]; then
  cd ~/Downloads
  block iso
  show 'ls'
  show 'grep live-server-amd64 SHA256SUMS'
  show 'sha256sum -c --ignore-missing SHA256SUMS'
  exit 0
fi

cd ~
sudo apt-get purge -y -qq powershell packages-microsoft-prod > /dev/null 2>&1
sudo apt-get update -qq > /dev/null 2>&1

block first-look
show 'hostname'
show 'grep PRETTY_NAME /etc/os-release'
show 'id'

block no-powershell
show 'sudo apt install -y powershell'

block powershell
show 'source /etc/os-release'
show 'wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb'
show 'sudo dpkg -i packages-microsoft-prod.deb'
show 'sudo apt update > apt.log 2>&1; grep microsoft apt.log'
show 'sudo apt install -y powershell > pwsh.log 2>&1; grep "^Setting up" pwsh.log'
show 'pwsh --version'
rm -f packages-microsoft-prod.deb apt.log pwsh.log

sudo sed -i '/^127\.0\.1\.1 /d' /etc/hosts
block no-host
show 'sudo true'
show 'cat /etc/hostname'
show 'grep server /etc/hosts'
show "echo '127.0.1.1 server' | sudo tee -a /etc/hosts"
show 'sudo true'

cd ~ && rm -rf ~/office
stage processes.md 'mkdir ~/office && cd ~/office'

block processes
session <<'S'
sleep 600 &
sleep 600 &
ps -o pid,ppid,stat,comm
S

block one-process
session <<'S'
sleep 600 &
grep -E '^(Name|State|PPid|Threads|VmRSS)' /proc/$!/status
kill %1
ps -o pid,comm
S

block cores
show 'nproc'
show "lscpu | grep -E '^(CPU\\(s\\)|Model name|Core\\(s\\) per socket)'"

block memory
show 'free -h'

block syscalls
show 'strace -e trace=openat,read,write -o trace.txt cat notice.txt'
show 'grep -A3 notice.txt trace.txt'

block devices
show 'ls /dev | head -12'
show 'ls -l /dev/null /dev/tty'
pkill -u ana sleep 2>/dev/null; true
