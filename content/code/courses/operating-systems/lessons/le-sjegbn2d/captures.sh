#!/usr/bin/env bash
# The terminal session quoted in lesson 13 of operating-systems, as a script that produces it.
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
# the Ubuntu 24.04 server from lesson 3, with one user, ana; a folder ~/work
# holding clients.csv, invoices/104.txt, reports/q3.txt and a 3 MB
# reports/scan.pdf of zeros, all dated 1 September 2026 by touch; one
# `sleep 600` started in the background before the first block, to have a
# process to find and stop; the PowerShell lines of a block run in ONE pwsh
# process, each shown after its prompt; and sudo set to ask ana for no
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
rm -rf ~/work && mkdir -p ~/work/invoices ~/work/reports
printf 'id,name,city\n1,Acme Ltd,Sao Paulo\n2,Bravo & Filhos,Campinas\n' > ~/work/clients.csv
printf 'Invoice 104 for Acme Ltd\n' > ~/work/invoices/104.txt
printf 'Q3 summary, Bravo & Filhos\n' > ~/work/reports/q3.txt
head -c 3000000 /dev/zero > ~/work/reports/scan.pdf
find ~/work -exec touch -h -d '2026-09-01 09:00' {} +
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
sleep 600 &
SLEEPER=$!

block machine
show 'hostname'
show 'nproc'
show 'uptime -p'
pss <<'S'
[Environment]::MachineName
[Environment]::ProcessorCount
S

block processes
show 'ps -eo pid,user,comm --sort=pid | head -6'
show 'pgrep -a sleep'
pss <<'S'
Get-Process -Name sleep | Select-Object Id, ProcessName
Get-Process | Measure-Object | Select-Object Count
S

block stop
show "kill $SLEEPER"
show 'pgrep -a sleep || echo "no sleep left"'

block disk
show 'df -h /'
show 'du -sh work'
show 'du -sh work/*'
pss <<'S'
Get-PSDrive -PSProvider FileSystem | Select-Object Name, Root
(Get-ChildItem work -Recurse -File | Measure-Object -Property Length -Sum).Sum
S

block search
show "find work -name '*.txt'"
show 'grep -rn "Acme" work'
pss <<'S'
Get-ChildItem work -Recurse -Filter *.txt -Name
Select-String -Path work/*/*.txt, work/*.csv -Pattern Acme
S

block environment
show 'echo $HOME'
show 'echo $PATH | tr ":" "\n" | head -4'
show 'printenv USER SHELL'
pss <<'S'
$env:HOME
$env:USER
S

block which
show 'type ls cd grep'
pss <<'S'
Get-Command ls, Get-ChildItem, grep | Select-Object CommandType, Name
S
