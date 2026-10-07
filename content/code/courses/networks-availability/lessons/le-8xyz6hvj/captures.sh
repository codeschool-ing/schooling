#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of networks-availability, as a
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
# THERE IS NO SLOW LINK IN THE LAB, SO ONE IS MADE, and the lesson shows each
# command that makes it: a shaper (tc's token bucket, tbf) on hq's uplink,
# and a policer (an nftables limit that drops what exceeds it) on the ISP's
# side of the same link, which is where a provider polices a contract.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the shaper removed as root before the
# policer is set; and the policer's counter zeroed, by deleting the rule and
# adding it again as root, before the last block.
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

lab reset

block baseline
on laptop 'iperf3 -c 192.0.2.21 -t 3 | tail -n 4'

block shape
on hq 'sudo tc qdisc add dev eth1 root tbf rate 5mbit burst 16kb latency 50ms'
BG_WAIT=0.2 bg laptop 'sleep 2; ping -c 5 -q 192.0.2.21 | tail -n 2'
on laptop 'iperf3 -c 192.0.2.21 -t 8'
fg
on hq 'tc -s qdisc show dev eth1'

block police
quiet hq 'tc qdisc del dev eth1 root'
on isp 'sudo nft add table ip contract && sudo nft add chain ip contract police "{ type filter hook forward priority 0; }"'
on isp 'sudo nft add rule ip contract police iifname eth0 ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter drop'
BG_WAIT=0.2 bg laptop 'sleep 2; ping -c 5 -q 192.0.2.21 | tail -n 2'
on laptop 'iperf3 -c 192.0.2.21 -t 8'
fg
on isp 'sudo nft list chain ip contract police'

block both
on hq 'sudo tc qdisc add dev eth1 root tbf rate 4500kbit burst 16kb latency 50ms'
quiet isp 'nft flush chain ip contract police; nft add rule ip contract police iifname eth0 ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter drop'
on laptop 'iperf3 -c 192.0.2.21 -t 8 | tail -n 4'
on isp 'sudo nft list chain ip contract police | grep counter'
