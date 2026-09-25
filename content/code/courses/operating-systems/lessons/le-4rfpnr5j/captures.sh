#!/usr/bin/env bash
# The terminal session quoted in lesson 15 of operating-systems, as a script that produces it.
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
# the Ubuntu 24.04 server from lesson 3, with one user, ana, in the sudo group,
# and what earlier lessons left in her home; /etc/hosts copied aside before the
# first block and put back at the end, with systemd-resolved restarted so it
# forgets the test entry; the PowerShell lines of a block run in ONE pwsh
# process, each shown after its prompt, and an error printed as the prompt
# prints it; and sudo set to ask ana for no password, which a real
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
sudo cp /etc/hosts /root/hosts.orig
# PowerShell as one session: each line is shown after the PS prompt and run in
# the same process, so Set-Location carries over to the next line as it does
# for a person typing at it. An error is printed as the prompt prints it,
# Command: message, without the position inside this helper's script.
pss() {
  local f=/tmp/pss.$$.ps1
  { echo '$ErrorView = "ConciseView"'
    while IFS= read -r l; do
      printf 'Write-Output ("PS " + (Get-Location).Path + "> " + %s)\n' "'${l//\'/\'\'}'"
      printf 'try { %s 2>&1 | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.InvocationInfo.MyCommand.Name + ": " + $_.Exception.Message } else { $_ } } | Out-String -Width 100 -Stream | ForEach-Object { $_.TrimEnd() } } catch { $_.InvocationInfo.MyCommand.Name + ": " + $_.Exception.Message }\n' "$l"
    done; } > $f
  pwsh -NoProfile -NoLogo -File $f 2>&1
  rm -f $f
}

block etc
show 'ls /etc | wc -l'
show 'cat /etc/hostname'
show 'cat /etc/hosts'
show 'dpkg -S /etc/hosts /etc/crontab'

block reading
show 'wc -l /etc/systemd/journald.conf'
show "grep -Ev '^(#|\$)' /etc/systemd/journald.conf"
show "grep -n 'Storage' /etc/systemd/journald.conf"
show 'ls /etc/apt/apt.conf.d'

block safe-edit
show 'sudo cp /etc/hosts /etc/hosts.bak'
show "echo '192.168.1.50  printer.office' | sudo tee -a /etc/hosts"
show 'diff /etc/hosts.bak /etc/hosts'
show 'getent hosts printer.office'
show 'sudo mv /etc/hosts.bak /etc/hosts'
show 'cat /etc/hosts'

block dotfiles
show 'ls -A ~'
show 'grep -c . ~/.bashrc'
show "grep -n 'HISTSIZE' ~/.bashrc"
pss <<'S'
$PROFILE
S

block no-registry
pss <<'S'
Get-PSDrive -PSProvider Registry
Get-ChildItem HKLM:\SOFTWARE
S

sudo cp /root/hosts.orig /etc/hosts
sudo systemctl restart systemd-resolved
