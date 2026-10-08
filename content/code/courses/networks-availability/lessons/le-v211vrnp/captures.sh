#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of networks-availability, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana     # once, on a throwaway machine,
#                                        # with passwordless sudo for ana
#   sudo -u ana -i bash /path/to/captures.sh
#
# lab.sh, beside course.json, extracts netlab.sh and tunnel.py from lesson 1's
# pages and installs them where that lesson tells the student to; the captures
# run the student's own copy.
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh: a head
# office (hq), a branch, a home behind its own NAT, an ISP and a small data
# centre, as network namespaces on one Linux computer.
#
# WHAT THE STUDENT DOES THAT A TRANSCRIPT DOES NOT SHOW, and where the lesson
# gives it. Every sh fence is EXTRACTED with `lab.sh fence` and typed as ana
# with sudo: hq moved to .2 with the MAC that goes with it (one-gateway), and
# keepalived started on hq2 and then on hq (election). hq's keepalived.conf is
# EXTRACTED from one-gateway's example, and hq2's is the same file with the
# priority the prose names. Each "cable pulled" or "WAN lost" is the command
# the prose gives, typed on the computer itself: a router's end of the pair
# on netlab.sh's wire namespace set down, and later up.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-$(cd "$(dirname "$0")/../.." && pwd)/lab.sh}
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
# bg HOST 'command': start a command that has to be running while something
# else happens (a capture, a server); its transcript is printed by fg.
BG=$(mktemp -d)
bg() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*" > "$BG/out"
  ( timeout -s INT 40 sudo bash "$LAB_SH" exec "$h" ana "$*" >> "$BG/out" 2>&1 || true ) &
  echo $! > "$BG/pid"
  sleep "${BG_WAIT:-1.5}"
}
fg() { wait "$(cat "$BG/pid")" 2>/dev/null || true; cat "$BG/out"; }
block() { printf '##### %s\n' "$1"; }
HERE=$(cd "$(dirname "$0")" && pwd)
fence() { lab exec "$1" ana "$(bash "$LAB_SH" fence "$HERE/$2" "$3")" >/dev/null 2>&1 || true; }
ka_start() { fence "$1" election.md 1; }
port() { sudo ip -n wire link set "$1" "$2"; }   # port hq-hq down: the cable

lab reset
fence hq one-gateway.md 1
bash "$LAB_SH" example "$HERE/one-gateway.md" keepalived.conf | lab exec hq root 'cat > /etc/keepalived/keepalived.conf'
bash "$LAB_SH" example "$HERE/one-gateway.md" keepalived.conf | sed 's/priority 150/priority 100/' |
  lab exec hq2 root 'cat > /etc/keepalived/keepalived.conf'

block config
on hq 'cat /etc/keepalived/keepalived.conf'

block elect
ka_start hq2; sleep 1; ka_start hq; sleep 5
on hq 'ip -br addr show eth0'
on hq2 'ip -br addr show eth0'
on hq 'grep -E "STATE|Entering" /run/keepalived.log'
on hq2 'grep -E "STATE|Entering" /run/keepalived.log'

block adverts
on laptop 'sudo tcpdump -n -t -i eth0 -c 3 vrrp'
on laptop 'ip -br link show dev eth0; ping -c 1 -q 192.168.10.1 >/dev/null; ip neigh show 192.168.10.1'
on laptop 'ip route'

block failover
BG_WAIT=0.5 bg laptop 'ping -D -O -i 0.2 -c 40 -W 1 192.0.2.21'
sleep 2
port hq-hq down
fg
on hq2 'grep -E "Entering" /run/keepalived.log'
on laptop 'ip neigh show 192.168.10.1'

block garp
BG_WAIT=0.5 bg laptop 'sudo tcpdump -n -t -e -i eth0 -c 2 arp and ether src 52:54:00:a8:0a:02'
port hq-hq up
fg
on hq 'grep -E "Entering" /run/keepalived.log'
on laptop 'ip neigh show 192.168.10.1'

block track
port hqwan-hq down
sleep 5
on hq 'grep -E "eth1|FAULT|Entering" /run/keepalived.log | tail -n 3'
on hq2 'ip -br addr show eth0'
on laptop 'ping -c 2 192.0.2.21'
port hqwan-hq up
sleep 5
on hq 'grep -E "eth1|FAULT|Entering" /run/keepalived.log | tail -n 3'
