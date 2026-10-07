#!/usr/bin/env bash
# The terminal session quoted in lesson 8 of operating-systems, as a script that produces it.
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
# the Ubuntu 24.04 server from lesson 3, with one user, ana, in the sudo group,
# and what lessons 1 and 3 left in her home; the folder ~/office, which is the
# lesson's own fence in moving-around, run by stage();
# the PowerShell lines of a block run in ONE pwsh process, each shown after its
# prompt, so a Set-Location carries over to the next line as it does for a
# person typing; and sudo set to ask ana for no password, which a real
# installation does not do.
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
stage moving-around.md "rm -rf ~/office && mkdir -p ~/office/clients ~/office/'invoices 2026' ~/office/scans"
# PowerShell as one session: each line is shown after the PS prompt and run in
# the same process, so Set-Location carries over to the next line as it does
# for a person typing at it.
pss() {
  local f=/tmp/pss.$$.ps1
  { echo '$ErrorView = "ConciseView"'
    while IFS= read -r l; do
      printf 'Write-Output ("PS " + (Get-Location).Path + "> " + %s)\n' "'${l//\'/\'\'}'"
      printf 'try { %s 2>&1 | Out-String -Width 100 -Stream | ForEach-Object { $_.TrimEnd() } } catch { $_ | Out-String -Width 100 -Stream | ForEach-Object { $_.TrimEnd() } }\n' "$l"
    done; } > $f
  pwsh -NoProfile -NoLogo -File $f 2>&1
  rm -f $f
}

block prompt
show 'whoami'
show 'hostname'
show 'pwd'

block root
session <<'S'
sudo -s
whoami
exit
S

block move
session <<'S'
pwd
ls
cd office
ls
cd clients
pwd
cd ..
cd /etc
pwd
cd -
cd ~
pwd
S

block ls-options
show 'ls -l office'
show 'ls -a office'
show 'ls -lh office/"invoices 2026"'

block spaces
session <<'S'
cd office
cd invoices 2026
cd "invoices 2026"
pwd
S

block case
session <<'S'
cd office
ls Notes.txt
ls notes.txt
S

block ps-move
pss <<'S'
Get-Location
Set-Location office
Get-ChildItem
Set-Location 'invoices 2026'
Get-Location
Set-Location ..
cd clients
pwd
S

block aliases
pss <<'S'
Get-Alias cd, pwd, dir, gci
Get-Command ls
S

block help
show 'ls --help | head -8'
show 'type cd ls'
pss <<'S'
(Get-Command -Verb Get).Count
Get-Command -Noun Location | Select-Object Name
S

block objects
show 'ls -l office/clients'
pss <<'S'
Get-ChildItem office/clients | Select-Object Name, Length, LastWriteTime
Get-ChildItem office/clients | Where-Object Length -gt 20
S

block history
session <<'S'
cd office
ls
cd clients
history
S

block noman
session <<'S'
man ls
S
