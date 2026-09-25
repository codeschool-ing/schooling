#!/usr/bin/env bash
# The terminal session quoted in lesson 14 of operating-systems, as a script that produces it.
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
# three files written with sudo tee before the first block, and removed with
# ana's crontab and the backup at the end: /usr/local/bin/office-backup, a
# two-line script that tars /etc/apt into /var/backups, and the two unit files
# the unit block prints; the server's own clock zone is UTC, as lesson 3's
# timedatectl showed; and sudo set to ask ana for no password, which a real
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
crontab -r 2>/dev/null
sudo systemctl disable --now office-backup.timer >/dev/null 2>&1
sudo rm -f /etc/systemd/system/office-backup.service /etc/systemd/system/office-backup.timer /usr/local/bin/office-backup /var/backups/etc-apt.tar.gz
printf '#!/bin/sh\ntar -czf /var/backups/etc-apt.tar.gz -C /etc apt && echo "backup written: /var/backups/etc-apt.tar.gz"\n' | sudo tee /usr/local/bin/office-backup >/dev/null
sudo chmod 755 /usr/local/bin/office-backup
printf '[Unit]\nDescription=Copy /etc/apt to /var/backups\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/office-backup\n' | sudo tee /etc/systemd/system/office-backup.service >/dev/null
printf '[Unit]\nDescription=Run office-backup every weekday at 02:00\n\n[Timer]\nOnCalendar=Mon..Fri 02:00\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n' | sudo tee /etc/systemd/system/office-backup.timer >/dev/null

block running
show 'systemctl list-units --type=service --state=running --no-pager --no-legend'
show 'sudo systemctl status cron --no-pager -n 0'

block control
show 'sudo systemctl stop cron'
show 'systemctl is-active cron'
show 'systemctl is-enabled cron'
show 'sudo systemctl start cron'
show 'systemctl is-active cron'

block boot
show 'systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend'

block unit
show 'cat /etc/systemd/system/office-backup.service'
show 'cat /etc/systemd/system/office-backup.timer'

block timer
show 'sudo systemctl daemon-reload'
show 'sudo systemctl enable --now office-backup.timer'
show 'systemctl list-timers office-backup.timer --no-pager'
show 'sudo systemctl start office-backup.service'
show 'sudo journalctl -u office-backup.service --no-pager -o cat | tail -3'
show 'ls -lh /var/backups/etc-apt.tar.gz'

block cron
show 'crontab -l'
show "echo '30 18 * * 1-5 df -h / >> /home/ana/disk.log' | crontab -"
show 'crontab -l'
show 'ls /etc/cron.daily'

crontab -r 2>/dev/null
sudo systemctl disable --now office-backup.timer >/dev/null 2>&1
sudo rm -f /etc/systemd/system/office-backup.service /etc/systemd/system/office-backup.timer /usr/local/bin/office-backup /var/backups/etc-apt.tar.gz
sudo systemctl daemon-reload
