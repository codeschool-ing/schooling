#!/usr/bin/env bash
# The terminal session quoted in lesson 17 of operating-systems, as a script that produces it.
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
# /usr/local/bin/office-report, a two-line script that writes df's output to
# /srv/reports, and office-report.service to run it, both written with sudo
# tee before the first block, with /srv/reports absent; all three removed
# again at the end; the journal also holds earlier runs of this script, so
# its lines are read with -n; the server started fresh just before the
# recording, so -b holds only this run; and sudo set to ask ana for no password, which
# a real installation does not do.
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
sudo systemctl reset-failed office-report.service >/dev/null 2>&1
sudo rm -f /etc/systemd/system/office-report.service /usr/local/bin/office-report
sudo rm -rf /srv/reports
printf '#!/bin/sh\ndf -h / > /srv/reports/disk-$(date +%%F).txt\necho "report written"\n' | sudo tee /usr/local/bin/office-report >/dev/null
sudo chmod 755 /usr/local/bin/office-report
printf '[Unit]\nDescription=Write the daily disk report\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/office-report\n' | sudo tee /etc/systemd/system/office-report.service >/dev/null
sudo systemctl daemon-reload

block journal
show 'sudo journalctl --disk-usage'
show 'sudo journalctl -u cron -n 3 --no-pager'
show 'sudo journalctl -b -p err --no-pager -o cat | cut -c1-90 | tail -2'

block quiet
show 'sudo systemctl start office-report.service'
show 'systemctl --failed --no-pager --no-legend'
show 'ls /srv/reports'
show 'sudo journalctl -u office-report.service --no-pager -o cat -n 5'

block loud
show 'cat /usr/local/bin/office-report'
show "sudo sed -i '2i set -e' /usr/local/bin/office-report"
show 'sudo systemctl start office-report.service'
show 'systemctl --failed --no-pager --no-legend'
show 'systemctl status office-report.service --no-pager -n 0 | head -3'

block fix
show 'sudo mkdir /srv/reports'
show 'sudo systemctl start office-report.service'
show 'systemctl is-failed office-report.service'
show 'ls /srv/reports'

sudo systemctl reset-failed office-report.service >/dev/null 2>&1
sudo rm -f /etc/systemd/system/office-report.service /usr/local/bin/office-report
sudo rm -rf /srv/reports
sudo systemctl daemon-reload
