#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana       # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh    # the lab, beside course.json
#   sudo bash captures.sh
#
# The lab is lab.sh's "office" scenario: pc1, pc2, pc3 and srv in
# 10.20.10.0/24 behind r1, which has the office's one public address,
# 203.0.113.2, and does NAT; the provider isp; and a web service at
# 192.0.2.80 outside. srv runs a web server on port 80.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up office`, whose r1 already has the masquerade rule the
# lesson prints; r1's connection-tracking table emptied before the PAT block,
# so it lists only the connections the block makes; and the connections the
# PAT block lists, held open for a few seconds by `sleep | nc` so they are
# still there when conntrack is asked.
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() { local h=$1; shift; printf 'ana@%s:~$ %s\n' "$h" "$*"; lab exec "$h" ana "$*" 2>&1 || true; }
# root HOST 'command': the same at a root prompt, on a device being configured.
root() { local h=$1; shift; printf 'root@%s:~# %s\n' "$h" "$*"; lab exec "$h" root "$*" 2>&1 || true; }
# quiet HOST 'command': the lab's own housekeeping, run as root and not shown.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while another does something, the way
# a second terminal would be: its prompt and output are printed when it ends.
bgon() {  # bgon USER HOST 'command'
  local p='$'; [ "$1" = root ] && p='#'
  printf '%s@%s:~%s %s\n' "$1" "$2" "$p" "$3" > /tmp/bg.out
  lab exec "$2" "$1" "$3" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep 2
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

lab up office

block addresses
on pc1 'ip -br addr show eth0'
root r1 'ip -br addr'
root r1 'nft list table ip nat'

block source-nat
bgon root r1 'timeout 6 tcpdump -n -i any -c 4 icmp'
on pc1 'ping -c 1 192.0.2.80'
fgon

block pat
quiet r1 'conntrack -F'
lab exec pc1 ana 'sleep 4 | timeout 6 nc -N -p 40000 192.0.2.80 80' >/dev/null 2>&1 &
lab exec pc2 ana 'sleep 4 | timeout 6 nc -N -p 40000 192.0.2.80 80' >/dev/null 2>&1 &
lab exec pc3 ana 'sleep 4 | timeout 6 nc -N -p 51000 192.0.2.80 80' >/dev/null 2>&1 &
sleep 2
root r1 'conntrack -L -p tcp'
wait

block what-outside-sees
bgon root isp 'timeout 8 tcpdump -n -i eth1 -c 3 "tcp[tcpflags] == tcp-syn"'
on pc1 'curl -s http://192.0.2.80/'
on pc2 'curl -s http://192.0.2.80/'
on pc3 'curl -s http://192.0.2.80/'
fgon

block inbound
root isp 'ip route add 10.20.10.0/24 via 203.0.113.2'
root isp 'curl -s -m 4 http://10.20.10.10/; echo "exit status $?"'
root isp 'curl -s -m 4 http://203.0.113.2:8080/; echo "exit status $?"'

block port-forward
root r1 'nft add chain ip nat prerouting "{ type nat hook prerouting priority dstnat; }"'
root r1 'nft add rule ip nat prerouting iifname "eth1" tcp dport 8080 dnat to 10.20.10.10:80'
root r1 'nft insert rule inet filter forward ct status dnat accept'
root isp 'curl -s -m 4 http://203.0.113.2:8080/'
root r1 'conntrack -L -p tcp --dport 8080'
root r1 'nft list ruleset'

block hairpin
on pc2 'curl -s -m 4 http://203.0.113.2:8080/; echo "exit status $?"'
