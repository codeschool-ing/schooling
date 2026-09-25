#!/usr/bin/env bash
# The terminal session quoted in lesson 12 of operating-systems, as a script that produces it.
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
# the Ubuntu 24.04 server from lesson 3, with one user, ana; a folder ~/work,
# emptied first, holding backup.log, 240 lines written by a loop, and
# clients.csv, four lines written by printf; five empty files touched into
# invoices before the wildcard block; the PowerShell lines of a block run in
# ONE pwsh process, each shown after its prompt; and sudo set to ask ana for
# no password, which a real installation does not do.
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
rm -rf ~/work && mkdir ~/work && cd ~/work
for i in $(seq 1 240); do printf '2026-09-%02d 09:%02d backup ok\n' $(( (i-1)/10 + 1 )) $(( (i-1) % 60 )); done > backup.log
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
printf 'id,name,city\n1,Acme Ltd,Sao Paulo\n2,Bravo & Filhos,Campinas\n3,Casa Verde,Santos\n' > clients.csv

block create
show 'mkdir invoices'
show 'mkdir reports/2026/q3'
show 'mkdir -p reports/2026/q3'
show 'touch notes.txt'
show 'echo "call the printer company" > todo.txt'
tty 'ls -F'
show 'find reports'

block read
show 'cat clients.csv'
show 'wc -l backup.log clients.csv'
show 'head -3 backup.log'
show 'tail -2 backup.log'
show 'grep -c ok backup.log'

block redirect
show 'cat todo.txt'
show 'echo "order toner" >> todo.txt'
show 'cat todo.txt'
show 'echo "renew the domain" > todo.txt'
show 'cat todo.txt'

block copy-move
show 'cp clients.csv clients-backup.csv'
show 'mv todo.txt notes-todo.txt'
show 'mv clients-backup.csv invoices/'
show 'cp -r reports reports-copy'
tty 'ls -F . invoices'

block wildcards
touch invoices/march.pdf invoices/april.pdf invoices/may.pdf invoices/draft.tmp invoices/old.tmp
tty 'ls invoices'
tty 'ls invoices/*.pdf'
show 'echo invoices/*.tmp'
tty 'ls invoices/ma*'
tty 'ls invoices/???.pdf'
tty 'ls invoices/*.doc'

block delete
show 'rm invoices/*.tmp'
tty 'ls invoices'
show 'rmdir reports-copy'
show 'rm -r reports-copy'
session <<'S'
rm -i notes.txt
n
ls
S

block ps
cd ~/work
pss <<'S'
New-Item -ItemType Directory -Path archive
Set-Content -Path archive/readme.txt -Value 'old invoices, kept for five years'
Add-Content -Path archive/readme.txt -Value 'ask the accountant before deleting'
Get-Content archive/readme.txt
Get-Content backup.log -Tail 2
Copy-Item clients.csv archive/
Remove-Item archive -Recurse -WhatIf
Get-ChildItem archive -Name
S
