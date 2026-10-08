#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from one run of it, block by block, into the lesson.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, with soclab.sh (the lab.sh beside
# course.json) in root's home folder and ana's key pair from lesson 1. Commands
# at the root@soc prompt run as root and those at ana@soc as ana, each with a
# clean environment.
#
# STAGED, NOT TYPED: keyaudit.sh and files-egress.nft, beside this script, are
# the files the lesson prints and tells the student to write; they are copied
# into root's home folder. The lab is built fresh at the start. At the end the
# script undoes what the lesson leaves in place on purpose (the keys-only
# drop-in, the second key, the web server), so that re-running an earlier
# lesson's captures.sh finds the machine as that lesson expects it.
#
# Recorded on Ubuntu 24.04 with OpenSSH 9.6p1 and nftables 1.0.9, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
ana()  { printf 'ana@soc:~$ %s\n' "$*"; runuser -u ana -- env -i ${ENV/HOME=\/root/HOME=/home/ana} bash -c "cd; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root && env -i $ENV bash -c "$*") >/dev/null 2>&1; }

install -m 755 "$HERE/../../lab.sh" /root/soclab.sh
install -m 644 "$HERE/keyaudit.sh" "$HERE/files-egress.nft" /root/
quiet 'bash soclab.sh down; rm -f /root/inventory.txt /etc/ssh/sshd_config.d/50-keys-only.conf'
quiet 'bash soclab.sh up'
runuser -u ana -- sh -c 'rm -f ~/.ssh/new_laptop ~/.ssh/new_laptop.pub; cp ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys'
sleep 2

block inventory
root "ssh-keygen -lf /home/ana/.ssh/id_ed25519.pub | awk '{print \$2, \"ana, work laptop\"}' > inventory.txt"
root 'cat inventory.txt'
root 'bash keyaudit.sh inventory.txt'

block unknown
ana "ssh-keygen -q -t ed25519 -N '' -C ana@new-laptop -f ~/.ssh/new_laptop"
ana 'cat ~/.ssh/new_laptop.pub >> ~/.ssh/authorized_keys'
root 'bash keyaudit.sh inventory.txt'

block register
root "ssh-keygen -lf /home/ana/.ssh/new_laptop.pub | awk '{print \$2, \"ana, new laptop, confirmed in person\"}' >> inventory.txt"
root 'bash keyaudit.sh inventory.txt'

block harden
root "sshd -T | grep -E '^(password|pubkey)authentication'"
root "echo 'PasswordAuthentication no' > /etc/ssh/sshd_config.d/50-keys-only.conf"
root "sshd -T | grep -E '^(password|pubkey)authentication'"

block rebuild
root 'bash soclab.sh down'
root 'bash soclab.sh up'
root 'ip netns exec fw nft list chain ip fw forward'
root 'ip -n outside addr add 203.0.113.150/24 dev eth0'
root 'ip netns exec outside python3 -m http.server 8080 >/dev/null 2>&1 &'
sleep 2
root 'ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/'

block reapply
root 'cat files-egress.nft'
root 'ip netns exec fw nft -f files-egress.nft'
root 'ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/; echo "exit $?"'
root 'ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/'

block verify
root 'ip netns exec outside ssh -o BatchMode=yes -o PreferredAuthentications=password -o StrictHostKeyChecking=accept-new ana@198.51.100.22 true'
root 'ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ana@198.51.100.22 hostname'
root 'tail -n 4 /var/log/soclab/gw-auth.log'

quiet 'ip netns pids outside | xargs -r kill'
rm -f /etc/ssh/sshd_config.d/50-keys-only.conf
runuser -u ana -- sh -c 'rm -f ~/.ssh/new_laptop ~/.ssh/new_laptop.pub; cp ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys'
