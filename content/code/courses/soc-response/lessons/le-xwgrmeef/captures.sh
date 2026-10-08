#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from one run of it, block by block, into the lesson.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is an Ubuntu 24.04 computer prepared exactly as the lesson tells
# the student to prepare theirs: the packages of "Your lab" installed, a user
# ana, and soclab.sh (the lab.sh beside course.json, byte for byte the script
# the lesson prints) in root's home folder. Commands at the root@soc prompt run
# as root; commands at ana@soc run as ana. Each runs with a clean environment.
#
# STAGED, NOT TYPED: nothing. The lab is torn down and built again at the start,
# the log directory is emptied first, and ana's key pair is made fresh, so its
# fingerprint, the source ports, the MAC addresses and every time stamp differ
# from run to run; the lesson quotes none of them as a fact.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
ana()  { printf 'ana@soc:~$ %s\n' "$*"; runuser -u ana -- env -i ${ENV/HOME=\/root/HOME=/home/ana} bash -c "cd; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root && env -i $ENV bash -c "$*") >/dev/null 2>&1; }

install -m 755 "$HERE/../../lab.sh" /root/soclab.sh
quiet 'bash soclab.sh down; rm -rf /var/log/soclab /root/one.pcap'
rm -rf /home/ana/.ssh

block up
root 'bash soclab.sh up'
root 'ip netns list'
root 'ip -n fw -br addr'

block key
ana "ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519"
ana 'cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys'

block login
quiet 'setsid ip netns exec fw tcpdump -U -i eth0 -w /root/one.pcap tcp port 22 </dev/null >/dev/null 2>&1 &'
sleep 2
root 'ip netns exec outside runuser -u ana -- ssh -o StrictHostKeyChecking=accept-new ana@198.51.100.22 hostname'
sleep 2
quiet 'pkill -x tcpdump'
# nfpcapd writes a record once the conversation has been quiet for 15
# seconds, into a file it closes once a minute: wait for that file
until nfdump -R /var/log/soclab/flows -q -o line 'port 22' 2>/dev/null | grep -q 203.0.113.66; do sleep 5; done

block sshd
root 'cat /var/log/soclab/gw-auth.log'

block fw
root 'cat /var/log/soclab/fw.log'

block flow
root "nfdump -R /var/log/soclab/flows -o line 'port 22'"

block pcap
root 'tcpdump -nr one.pcap | head -4'
root 'tcpdump -nr one.pcap | wc -l'

block sizes
root 'wc -c /var/log/soclab/gw-auth.log /var/log/soclab/fw.log one.pcap'
