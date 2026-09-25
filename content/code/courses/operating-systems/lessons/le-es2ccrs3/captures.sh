#!/usr/bin/env bash
# The terminal session quoted in lesson 9 of operating-systems, as a script that produces it.
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
# two more users, bruno and carla, made with useradd for the other side of
# each permission, and removed again at the end with the group accounts and
# both folders; /srv/office, owned by ana, holding payroll.txt and
# reports/q3.txt, dated 1 September 2026 by touch; backup.sh written by
# printf before its block; and sudo set to ask ana for no password, which a
# real installation does not do.
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
for u in bruno carla; do sudo userdel -r $u >/dev/null 2>&1; done
sudo groupdel accounts >/dev/null 2>&1
sudo rm -rf /srv/accounts
sudo useradd -m -s /bin/bash bruno
sudo useradd -m -s /bin/bash carla
sudo rm -rf /srv/office && sudo mkdir /srv/office && sudo chown ana:ana /srv/office
cd /srv/office && mkdir reports
printf 'Q3 figures\n' > reports/q3.txt
printf 'salaries\n' > payroll.txt
chmod 755 /srv/office reports
chmod 644 payroll.txt reports/q3.txt
find /srv/office -exec touch -h -d '2026-09-01 09:00' {} +

block read
show 'ls -l'
show 'id'
show 'id bruno'
show 'ls -ld /home/ana /home/bruno'

block others-read
show 'sudo -u bruno cat payroll.txt'
show 'chmod o-r payroll.txt'
show 'ls -l payroll.txt'
show 'sudo -u bruno cat payroll.txt'

block dir-x
show 'chmod o-x reports'
show 'ls -ld reports'
show 'sudo -u bruno ls reports'
show 'sudo -u bruno cat reports/q3.txt'
show 'chmod o+x reports'

block delete
show 'mkdir drop && chmod 777 drop'
show 'printf "draft\n" > drop/plan.txt && chmod 444 drop/plan.txt'
show 'ls -l drop'
show 'sudo -u bruno sh -c "echo change >> drop/plan.txt"'
show 'sudo -u bruno rm -f drop/plan.txt'
show 'ls -l drop'
show 'ls -ld /tmp'

block chmod
printf '#!/bin/sh\necho backup done\n' > backup.sh
session <<'S'
cat backup.sh
ls -l backup.sh
./backup.sh
chmod u+x backup.sh
./backup.sh
S
show 'chmod 640 payroll.txt'
show 'ls -l payroll.txt backup.sh'
show 'stat -c "%a %A %n" payroll.txt backup.sh'

block chown
show 'chown bruno payroll.txt'
show 'sudo chown bruno:bruno payroll.txt'
show 'ls -l payroll.txt'

block group
show 'sudo groupadd accounts'
show 'sudo usermod -aG accounts bruno'
show 'sudo mkdir /srv/accounts'
show 'sudo chown root:accounts /srv/accounts'
show 'sudo chmod 2770 /srv/accounts'
show 'ls -ld /srv/accounts'
show 'sudo -u bruno touch /srv/accounts/ledger.xlsx'
show 'sudo -u carla touch /srv/accounts/ledger.xlsx'
show 'sudo ls -l /srv/accounts'

block umask
show 'umask'
show 'touch new.txt && mkdir newdir'
show 'ls -ld new.txt newdir'

block ps-acl
psh 'Get-Acl payroll.txt'

cd ~
sudo rm -rf /srv/accounts /srv/office
for u in bruno carla; do sudo userdel -r $u >/dev/null 2>&1; done
sudo groupdel accounts >/dev/null 2>&1
