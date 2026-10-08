#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, with soclab.sh in root's home
# folder and lesson 4's week in /home/ana/week. Commands at root@soc run as
# root, in root's home folder.
#
# STAGED, NOT TYPED: playbook.py, beside this script, is the file the lesson
# prints and tells the student to write; it is copied to root's home folder.
# The lab is torn down and built fresh, and ana's week is rebuilt by running
# lesson 4's week.py and load.py in /home/ana/week, so siem.db holds exactly
# lesson 4's rows. Old tickets are removed first. The handle nft gives the
# playbook's rule is read from the listing printed just before it is used.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root && env -i $ENV bash -c "$*") >/dev/null 2>&1; }

install -m 755 "$HERE/../../lab.sh" /root/soclab.sh
install -m 644 "$HERE/playbook.py" /root/playbook.py
quiet 'bash soclab.sh down; rm -f /root/ticket-*.json; bash soclab.sh up'
runuser -u ana -- bash -c 'mkdir -p ~/week && cd ~/week && python3 week.py && python3 load.py' >/dev/null
sleep 2

block propose
root 'python3 playbook.py /home/ana/week/siem.db 203.0.113.66'

block ticket
root 'cat ticket-203.0.113.66.json'

block approve
root 'python3 playbook.py /home/ana/week/siem.db 203.0.113.66 --approve ana'
root 'ip netns exec fw nft list chain ip fw forward'
root 'ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 ana@198.51.100.22 true'

block guard
root 'python3 playbook.py /home/ana/week/siem.db 203.0.113.150 --approve ana'
root 'python3 playbook.py /home/ana/week/siem.db 192.168.20.10 --approve ana'

block undo
root 'ip netns exec fw nft -a list chain ip fw forward'
H=$(ip netns exec fw nft -a list chain ip fw forward | awk '/playbook/ {print $NF}')
root "ip netns exec fw nft delete rule ip fw forward handle $H"
root 'ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 ana@198.51.100.22 hostname'
