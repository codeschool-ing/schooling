#!/usr/bin/env bash
# The terminal session quoted in lesson 6 of operating-systems, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it on a
# newer system and see what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana   # once, on a throwaway machine
#   sudo -u ana -i bash /path/to/captures.sh    # hostname `server`
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
# the Ubuntu 24.04 server from lesson 3, updated, with one user, ana, in the
# sudo group; the package distro-info, which is where the release dates below
# come from, installed by the lesson's own fence, run by stage(); and sudo set to ask ana for no password,
# which a real installation does not do.
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
here=$(cd "$(dirname "$0")" && pwd)
stage() {
  local fence
  fence=$(first="$2" awk '
    /^```sh$/ { inside = 1; n = 0; next }
    /^```$/ && inside { if (keep) exit; inside = 0; next }
    inside { n++; if (n == 1 && $0 == ENVIRON["first"]) keep = 1; if (keep) print }
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

cd ~
export DEBIAN_FRONTEND=noninteractive
stage life-cycles.md 'sudo apt install -y distro-info' > /dev/null

block release
show 'cat /etc/os-release'

block debian
show 'cat /etc/debian_version'
show "apt-cache show bash | grep -E '^(Package|Maintainer|Original-Maintainer)' | sed -E 's/: .*@/: …@/'"
show "apt-cache dumpavail | grep -c '^Package:'"
show "apt-cache dumpavail | grep -c '^Original-Maintainer:.*debian'"

block sources
show 'cat /etc/apt/sources.list.d/ubuntu.sources'
show "apt-cache show bash cowsay | grep -E '^(Package|Section)'"

block life
show 'ubuntu-distro-info --series noble --fullname'
show 'ubuntu-distro-info --series noble --days=eol'
show 'ubuntu-distro-info --series noble --days=eol-esm'
show 'ubuntu-distro-info --supported --fullname'
show 'ubuntu-distro-info --lts'
show 'ubuntu-distro-info --devel'

block debian-life
show 'debian-distro-info --stable --fullname'
show 'debian-distro-info --supported'
