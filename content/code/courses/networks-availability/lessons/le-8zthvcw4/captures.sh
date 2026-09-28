#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of networks-availability, as a
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
# itself, built by lab.sh reset; and the traffic each capture catches,
# generated on laptop by the commands beside each bg line below (a few
# requests to web1, and one download of its 20 MB file).
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
  ( lab exec "$h" ana "$*" >> "$BG/out" 2>&1 || true ) &
  echo $! > "$BG/pid"
  sleep "${BG_WAIT:-1.5}"
}
fg() { wait "$(cat "$BG/pid")" 2>/dev/null || true; cat "$BG/out"; }
block() { printf '##### %s\n' "$1"; }
requests() { lab exec laptop ana 'for i in 1 2 3; do curl -s http://192.0.2.21/ >/dev/null; done; curl -s http://192.0.2.21/missing >/dev/null' >/dev/null 2>&1; }

lab reset

block permission
on web1 'tcpdump -i eth0'

block line
bg web1 'sudo tcpdump -i eth0 -c 4 tcp port 80'
lab exec laptop ana 'curl -s http://192.0.2.21/' >/dev/null 2>&1
fg
bg web1 'sudo tcpdump -n -i eth0 -c 4 tcp port 80'
lab exec laptop ana 'curl -s http://192.0.2.21/' >/dev/null 2>&1
fg

block write
bg web1 'sudo tcpdump -n -i eth0 -c 40 -Z ana -w web1.pcap tcp port 80'
requests
fg
on web1 'ls -l web1.pcap'
on web1 'capinfos web1.pcap'

block read
on web1 'tcpdump -n -r web1.pcap | head -n 6'
on web1 'tcpdump -n -r web1.pcap "tcp[tcpflags] & tcp-syn != 0"'
on web1 'tcpdump -n -A -r web1.pcap "tcp[tcpflags] & tcp-push != 0" | grep -E "GET|HTTP/1.1 [0-9]"'

block snaplen
bg web1 'sudo tcpdump -n -i eth0 -s 96 -c 40 -Z ana -w short.pcap tcp port 80'
requests
fg
on web1 'tcpdump -n -r short.pcap -v "tcp[tcpflags] & tcp-push != 0" | head -n 4'
on web1 'ls -l web1.pcap short.pcap'

block rotate
bg web1 'sudo tcpdump -n -i eth0 -s 96 -C 1 -W 3 -Z ana -w ring.pcap tcp port 80'
lab exec laptop ana 'curl -s -o /dev/null http://192.0.2.21/big.bin' >/dev/null 2>&1
sleep 1
lab kill web1 'tcpdump -n -i eth0 -s 96 -C 1' INT
fg
on web1 'ls -l ring.pcap*'

block tshark
on web1 'tshark -r web1.pcap -q -z http,tree'
