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
#   sudo cp ../../lab.sh /var/tmp/lab.sh  # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh: a head
# office (hq), a branch, a home behind its own NAT, an ISP and a small data
# centre, as network namespaces on one Linux computer.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; hq moved from 192.168.10.1 to 192.168.10.2,
# with the MAC address that goes with .2, so that .1 is free to become the
# virtual address; the two keepalived.conf
# files, written below as root (the lesson shows hq's with cat); keepalived
# started as root on both routers, in the foreground of a setsid, logging to
# /run/keepalived.log; and each "cable pulled" or "WAN lost", which is the
# router's port on the lab's bridge set down (lab.sh's wire namespace) and
# later set up again.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

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
ka_conf() {  # ka_conf HOST PRIORITY
  lab exec "$1" root 'cat > /etc/keepalived/keepalived.conf' <<C
vrrp_instance office {
    state BACKUP
    interface eth0
    virtual_router_id 10
    priority $2
    advert_int 1
    virtual_ipaddress {
        192.168.10.1/24
    }
    track_interface {
        eth1
    }
}
C
}
ka_start() { quiet "$1" 'setsid keepalived -n -l -f /etc/keepalived/keepalived.conf -p /run/keepalived.pid -r /run/vrrp.pid </dev/null >/run/keepalived.log 2>&1 &'; }
port() { sudo ip -n wire link set "$1" "$2"; }   # port hq-hq down: the cable

lab reset
quiet hq 'ip addr del 192.168.10.1/24 dev eth0; ip link set eth0 address 52:54:00:a8:0a:02; ip addr add 192.168.10.2/24 dev eth0'
ka_conf hq 150
ka_conf hq2 100

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
