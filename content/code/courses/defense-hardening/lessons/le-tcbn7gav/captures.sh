#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by ../../lab.sh from
# the hostlab.sh lesson 1 shows: web and desk are started fresh. A line that
# starts with ana@web ran on the machine called web, as ana.
#
# What is STAGED rather than typed:
# - jail.local and aide.conf are written into ana's home on web from this
#   lesson's own Markdown, byte for byte as the copy button hands them over:
#   the student pastes them.
# - the failed logins come from desk, from the student's own account, asking
#   web for an account that does not exist; nothing is guessed.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
put() {   # put HOST USER PATH FILE: write a file the lesson shows onto a machine
  python3 /var/tmp/dh/tools/fromlesson.py "$here" "$4" | lab exec "$1" "$2" "cat > $3"
}

lab up web desk >/dev/null 2>&1
for f in jail.local aide.conf; do put web ana "/home/ana/$f" "$f"; done

block default
on web 'sudo fail2ban-client status sshd'
on web 'sudo fail2ban-client get sshd maxretry; sudo fail2ban-client get sshd actions'

block jail
on web 'sudo cp jail.local /etc/fail2ban/ && sudo systemctl restart fail2ban && sleep 2 && sudo fail2ban-client get sshd maxretry'

block fail
on desk 'for i in 1 2 3 4; do ssh -o BatchMode=yes visitor@web true; done'

block banned
on web 'sleep 2; sudo fail2ban-client status sshd | tail -3'
on web 'sudo nft list table inet f2b-table'
on desk 'nc -zv -w3 web 22 2>&1; curl -s -m3 http://web/'

block log
on web 'sudo grep -E "Found|Ban" /var/log/fail2ban.log | cut -d" " -f2,6-'

block unban
on web 'sudo fail2ban-client set sshd unbanip 192.168.60.20'
on desk 'ssh web hostname'

block aide-init
on web 'sudo mkdir -p /var/lib/aide && sudo aide --config=aide.conf --init | tail -3'
on web 'sudo mv /var/lib/aide/portal.db.new /var/lib/aide/portal.db'

block aide-change
on web 'echo "# reviewed by the new administrator" | sudo tee -a /opt/portal/backup.sh'
on web 'echo "estagio ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/90-helpdesk'

block aide-check
on web 'sudo aide --config=aide.conf --check | head -34'
