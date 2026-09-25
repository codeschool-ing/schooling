#!/usr/bin/env bash
# The terminal session quoted in lesson 16 of operating-systems, as a script that produces it.
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
# sudo group; unattended-upgrades removed first, so each run installs it, and
# removed again at the end with the log its install wrote; the PowerShell lines
# of a block run in ONE pwsh process; DEBIAN_FRONTEND=noninteractive; and sudo
# set to ask ana for no password, which a real installation does not do.
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
sudo apt-get purge -y -qq unattended-upgrades >/dev/null 2>&1
sudo apt-get autoremove -y -qq >/dev/null 2>&1
sudo apt-mark unhold cron >/dev/null 2>&1
rm -f ~/uu.log
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

block changelog
show 'apt-cache policy openssl | head -3'
show 'zcat /usr/share/doc/openssl/changelog.Debian.gz | head -12'
show "zcat /usr/share/doc/openssl/changelog.Debian.gz | grep -c 'SECURITY UPDATE'"

block auto
show 'sudo apt install -y unattended-upgrades > uu.log 2>&1; grep "^Setting up" uu.log'
show 'cat /etc/apt/apt.conf.d/20auto-upgrades'
show "grep -A2 '^Unattended-Upgrade::Allowed-Origins' /etc/apt/apt.conf.d/50unattended-upgrades"
show 'systemctl list-timers apt-daily-upgrade.timer --no-pager'

block hold
show 'sudo apt-mark hold cron'
show 'apt-mark showhold'
show 'sudo apt-mark unhold cron'

block reboot
show 'ls /var/run/reboot-required'

block arch
show 'dpkg --print-architecture'
show 'ldd /usr/bin/ls'
show 'ldd --version | head -1'
pss <<'S'
$PSVersionTable.PSEdition
$PSVersionTable.PSVersion.ToString()
S

sudo apt-get purge -y -qq unattended-upgrades >/dev/null 2>&1
sudo apt-get autoremove -y -qq >/dev/null 2>&1
rm -f ~/uu.log
