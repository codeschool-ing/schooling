#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of networks-availability, as a
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
# EVERY LINK HERE IS INSTANT AND LOSSLESS UNTIL A LESSON SAYS OTHERWISE, and
# the times printed are one computer talking to itself. What is STAGED rather
# than typed, and not shown in the lesson:
#   - the lab itself, built by lab.sh reset;
#   - the loss: an nftables rule on the ISP router that drops two packets in
#     ten, at random, of those it forwards towards web2 (numgen random mod 10
#     < 2), added as root and removed before the second mtr;
#   - the silent hop: a rule on the ISP router that drops the "time
#     exceeded" messages it would send, added as root;
#   - the uplink: hq's link to the ISP shaped to 20 Mbit/s with tc before the
#     iperf3 block, the same way lessons 18 and 20 do it.
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
quiet isp 'nft add table ip lab'

block ping
on laptop 'ping -c 4 192.0.2.21'
on laptop 'ping -c 1 192.168.10.1 | grep ttl; ping -c 1 192.0.2.21 | grep ttl'
on laptop 'ping -c 3 -q -i 0.2 -s 1400 192.0.2.21'

block loss
quiet isp "nft add chain ip lab loss '{ type filter hook forward priority 0; }'; nft add rule ip lab loss 'ip daddr 192.0.2.22 numgen random mod 10 < 2 drop'"
on laptop 'ping -c 50 -i 0.1 -q 192.0.2.22'

block traceroute
on laptop 'traceroute -n 192.0.2.22'
on laptop 'traceroute -n -I 192.0.2.21'
on laptop 'sudo traceroute -n -T -p 80 192.0.2.21'

block silent
sleep 2
quiet isp 'nft add chain ip lab quiet "{ type filter hook output priority 0; }"; nft add rule ip lab quiet icmp type time-exceeded drop'
on laptop 'traceroute -n -q 1 192.0.2.21'
quiet isp 'nft flush chain ip lab quiet'

block mtr
sleep 2
on laptop 'sudo mtr -n -r -c 20 192.0.2.22'
quiet isp 'nft flush chain ip lab loss'
on laptop 'sudo mtr -n -r -c 50 -i 0.1 192.0.2.21'
on hq 'sysctl net.ipv4.icmp_ratelimit net.ipv4.icmp_ratemask'

block nslookup
on laptop 'nslookup www.example.com'
on laptop 'nslookup -type=ns example.com'
on laptop 'nslookup nosuch.example.com'
on laptop 'nslookup www.example.com 192.0.2.54'

block iperf
quiet hq 'tc qdisc add dev eth1 root tbf rate 20mbit burst 32kb latency 50ms'
on web1 'ss -tlnp | grep 5201'
on laptop 'iperf3 -c 192.0.2.21 -t 5'
on laptop 'iperf3 -c 192.0.2.21 -t 5 -R | tail -n 4'
on laptop 'iperf3 -c 192.0.2.21 -t 5 -P 4 | tail -n 4'
on laptop 'iperf3 -c 192.0.2.21 -t 5 -u -b 10M | tail -n 4'
on laptop 'iperf3 -c 192.0.2.21 -t 5 -u -b 30M | tail -n 4'
