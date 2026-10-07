#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of networks-availability, as a
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
# THERE IS NO SLOW LINK IN THE LAB, SO ONE IS MADE. Every cable here is a
# virtual one that moves gigabits with no delay. The lesson's first command
# makes hq's link to the ISP a 5 Mbit/s link with a queue of 100 packets,
# which is the shape of a small office's upload: that command is shown, and
# everything after it is measured through it.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; and the upload that fills the link, an
# iperf3 run from laptop to web1, started as ana beside each measurement
# (the lesson shows its summary where it matters).
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
upload() {  # upload SECONDS: fill hq's uplink from laptop, in the background
  ( lab exec laptop ana "iperf3 -c 192.0.2.21 -t $1" > "$BG/iperf" 2>&1 & )
  sleep 2
}

lab reset

block idle
on laptop 'ping -c 5 -q 192.0.2.21 | tail -n 1'

block one-queue
on hq 'sudo tc qdisc add dev eth1 root handle 1: htb default 20 && sudo tc class add dev eth1 parent 1: classid 1:20 htb rate 5mbit && sudo tc qdisc add dev eth1 parent 1:20 pfifo limit 100'
on hq 'tc qdisc show dev eth1; tc class show dev eth1'
on laptop 'ping -c 5 -q 192.0.2.21 | tail -n 1'
upload 10
on laptop 'ping -c 5 -q 192.0.2.21 | tail -n 1'
on laptop 'ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1'
sleep 5
on laptop 'iperf3 -c 192.0.2.21 -t 5 | tail -n 4'

block classes
quiet hq 'tc qdisc del dev eth1 root'
on hq 'sudo tc qdisc add dev eth1 root handle 1: htb default 20 && sudo tc class add dev eth1 parent 1: classid 1:1 htb rate 5mbit'
on hq 'sudo tc class add dev eth1 parent 1:1 classid 1:10 htb rate 1mbit ceil 5mbit prio 0 && sudo tc class add dev eth1 parent 1:1 classid 1:20 htb rate 4mbit ceil 5mbit prio 1'
on hq 'sudo tc qdisc add dev eth1 parent 1:10 pfifo limit 100 && sudo tc qdisc add dev eth1 parent 1:20 pfifo limit 100'
on hq 'sudo tc filter add dev eth1 parent 1: protocol ip prio 1 u32 match ip dsfield 0xb8 0xfc flowid 1:10'
upload 10
on laptop 'ping -c 5 -q 192.0.2.21 | tail -n 1'
on laptop 'ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1'
sleep 6
on hq 'tc -s class show dev eth1 | grep -A 1 -E "^class htb 1:(10|20)"'

block marking
bg isp 'sudo tcpdump -n -v -i eth0 -c 2 icmp'
lab exec laptop ana 'ping -c 1 -Q 0xb8 192.0.2.21' >/dev/null 2>&1
fg

block trust
on hq 'sudo nft add table ip qos && sudo nft add chain ip qos edge "{ type filter hook prerouting priority mangle; }"'
on hq 'sudo nft add rule ip qos edge iifname eth0 ip dscp set cs0 && sudo nft add rule ip qos edge iifname eth0 ip saddr 192.168.10.10 udp dport 5004 ip dscp set ef'
on hq 'sudo nft list table ip qos'
upload 10
on laptop 'ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1'
sleep 6
bg isp 'sudo tcpdump -n -v -i eth0 -c 1 udp port 5004'
lab exec files ana 'echo voice | nc -u -w1 192.0.2.21 5004' >/dev/null 2>&1
fg
