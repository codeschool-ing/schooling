#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of networks, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds an office, an
# ISP and a small internet out of network namespaces on one Linux computer,
# with its own DNS root and its own certificate authority. Nothing reaches the
# real internet, which is why the addresses and names are the ones reserved
# for documentation. A line that starts with ana@laptop ran on the machine
# called laptop, and so on.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset: sshd on server and on www, www's
# firewall accepting SSH only from the office's address, an admin page on
# server listening only on 127.0.0.1:8080, and the Ubuntu login banner
# switched off; ana's password is office-2026, typed where a prompt asks for
# it and not echoed; ~/.ssh/config written on laptop before the config
# block; the key made on laptop copied to ana's home on home, as she would
# carry it, and its public half put on www before the jump block; the
# machine's login records emptied before the first and the jump blocks,
# because every host in the lab shares them; and before the changed block,
# server's host key regenerated, as a reinstallation would.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# An interactive shell on one machine, in a real terminal, with the lines on
# stdin typed into it one at a time. Passwords and passphrases are typed too,
# and, as on any terminal, not echoed.
cat > /tmp/typed-shell.sh <<'SH'
printf 'set enable-bracketed-paste off\n' > /tmp/inputrc.$$
INPUTRC=/tmp/inputrc.$$ script -qec "env PS1='\u@\h:\w\$ ' HISTFILE=/dev/null bash --norc --noprofile -i" /dev/null
rm -f /tmp/inputrc.$$
SH
typed() {
  local h=$1 cmds; cmds=$(cat)
  { sleep 1; while IFS= read -r l; do printf '%s\n' "$l"; sleep "${PAUSE:-1.5}"; done <<< "$cmds"; printf 'exit\n'; sleep 0.5; } |
    timeout 90 sudo bash "$LAB_SH" exec "$h" ana 'bash /tmp/typed-shell.sh' | tr -d '\r' | sed '$d' | sed '$d'
}

lab reset
# A first connection has no earlier one: the machine's login records are
# shared by every host, so they would carry the last run's.
sudo truncate -s0 /var/log/wtmp /var/log/lastlog

block first
typed laptop <<'IN'
ssh 192.168.10.10
yes
office-2026
hostname
exit
IN

block fingerprint
on server 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'
on laptop 'cat ~/.ssh/known_hosts | cut -c1-60'

block keygen
on laptop 'ssh-keygen -t ed25519 -N "blue kettle on the roof" -C "ana@laptop" -f ~/.ssh/id_ed25519'
on laptop 'ls -l ~/.ssh'

block copy-id
typed laptop <<'IN'
ssh-copy-id -i ~/.ssh/id_ed25519.pub 192.168.10.10
office-2026
IN
on server 'cat ~/.ssh/authorized_keys | cut -c1-50; ls -ld ~/.ssh ~/.ssh/authorized_keys'

block agent
PAUSE=2 typed laptop <<'IN'
ssh 192.168.10.10 hostname
blue kettle on the roof
eval $(ssh-agent)
ssh-add
blue kettle on the roof
ssh-add -l
ssh 192.168.10.10 hostname
IN

block config
lab exec laptop ana 'printf "Host office\n    HostName 192.168.10.10\n    User ana\n\nHost web\n    HostName 192.0.2.80\n    User ana\n" > ~/.ssh/config; chmod 600 ~/.ssh/config' >/dev/null
on laptop 'cat ~/.ssh/config'
PAUSE=2 typed laptop <<'IN'
eval $(ssh-agent) >/dev/null
ssh-add
blue kettle on the roof
ssh office uptime -p
IN

block portforward
on router 'sudo nft add table ip nat'
on router "sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority dstnat; }'"
on router 'sudo nft add rule ip nat prerouting iifname "eth1" tcp dport 2222 dnat to 192.168.10.10:22'
on router 'sudo nft list chain ip nat prerouting'

block from-home
lab exec laptop ana 'cat ~/.ssh/id_ed25519.pub' > /tmp/laptop.pub
lab exec home ana 'mkdir -p ~/.ssh; chmod 700 ~/.ssh' >/dev/null
sudo install -o ana -g ana -m 600 /lab/laptop/home/ana/.ssh/id_ed25519 /lab/home/home/ana/.ssh/id_ed25519
sudo install -o ana -g ana -m 644 /lab/laptop/home/ana/.ssh/id_ed25519.pub /lab/home/home/ana/.ssh/id_ed25519.pub
PAUSE=2 typed home <<'IN'
ssh -p 2222 office.example.com
yes
blue kettle on the roof
hostname; who
exit
IN

block jump
# www already trusts the key: the admin put it there, as copy-id did on the server.
lab exec www ana 'mkdir -p ~/.ssh; chmod 700 ~/.ssh' >/dev/null
sudo install -o ana -g ana -m 600 /lab/laptop/home/ana/.ssh/id_ed25519.pub /lab/www/home/ana/.ssh/authorized_keys
on home 'ssh -o ConnectTimeout=5 192.0.2.80 hostname'
# ana has never logged into www; the shared login records would say otherwise.
sudo truncate -s0 /var/log/wtmp /var/log/lastlog
PAUSE=2 typed home <<'IN'
eval $(ssh-agent) >/dev/null
ssh-add
blue kettle on the roof
ssh -J ana@office.example.com:2222 www.example.com
yes
hostname
exit
IN

block tunnel
on laptop 'curl -sS -m 3 http://192.168.10.10:8080/'
on server 'ss -tln | grep 8080'
PAUSE=2 typed laptop <<'IN'
eval $(ssh-agent) >/dev/null
ssh-add
blue kettle on the roof
ssh -f -N -L 8080:127.0.0.1:8080 office
curl -s http://127.0.0.1:8080/
IN

block log
PAUSE=5 typed laptop <<'IN'
ssh -o PubkeyAuthentication=no office true
office-2025
office2026
Office-2026
IN
on server 'sudo grep -E "Accepted|Failed" /var/log/ssh/sshd.log'

block harden
on server 'echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config'
on server 'sudo sshd -t -f /etc/ssh/sshd_config && echo config ok'
on server 'sudo kill -HUP $(cat /run/sshd-server.pid)'
on server 'sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|pubkeyauthentication) "'
on laptop 'ssh -o PubkeyAuthentication=no -o BatchMode=yes office true'

block changed
# The server is reinstalled: it gets a new host key.
quiet server 'rm -f /etc/ssh/ssh_host_ed25519_key*; ssh-keygen -q -t ed25519 -N "" -C root@server -f /etc/ssh/ssh_host_ed25519_key; kill -HUP $(cat /run/sshd-server.pid)'
sleep 1
on laptop 'ssh -o BatchMode=yes office true'
on server 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'
on laptop 'ssh-keygen -R 192.168.10.10'
PAUSE=2 typed laptop <<'IN'
eval $(ssh-agent) >/dev/null
ssh-add
blue kettle on the roof
ssh office hostname
yes
IN

sudo pkill -x ssh-agent; sudo pkill -x ssh
lab down >/dev/null 2>&1
