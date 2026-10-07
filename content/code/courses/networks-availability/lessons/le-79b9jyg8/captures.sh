#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of networks-availability, as a
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
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, whose web1 serves TLS on four ports with four
# certificates made by lab.sh: a good one on 443, an expired one on 8443, one
# for another name on 9443, and one signed by an authority nobody trusts on
# 10443; the firewall rule on web1 that drops TCP 8080, added as root before
# the filtered block; and the lab's root certificate in laptop's trust store,
# put there by lab.sh. The requests name www.example.com and are sent to
# web1's own address with curl --resolve, because www's address belongs to
# the load balancers, which are not running in this lesson.
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
R='--resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21'

block handshake
bg laptop 'tshark -n -i eth0 -c 10 -f "host 192.0.2.21 and tcp port 80" -T fields -e frame.number -e ip.src -e tcp.flags.str -e tcp.seq -e tcp.ack -e tcp.len'
lab exec laptop ana 'curl -s http://192.0.2.21/' >/dev/null 2>&1
fg
bg laptop 'tshark -n -i eth0 -c 3 -f "host 192.0.2.21 and tcp port 80" -T fields -e frame.number -e tcp.flags.str -e tcp.seq_raw -e tcp.ack_raw'
lab exec laptop ana 'curl -s http://192.0.2.21/' >/dev/null 2>&1
fg

block refused
bg laptop 'tshark -n -i eth0 -c 2 -f "host 192.0.2.21 and tcp port 81"'
on laptop 'curl -sS http://192.0.2.21:81/'
fg

block filtered
quiet web1 'nft add table ip filter; nft add chain ip filter input "{ type filter hook input priority 0; }"; nft add rule ip filter input tcp dport 8080 drop'
bg laptop 'tshark -n -i eth0 -c 3 -f "host 192.0.2.21 and tcp port 8080"'
on laptop 'curl -sS --max-time 5 http://192.0.2.21:8080/'
fg

block dns
bg laptop 'tshark -n -i eth0 -c 4 -f "udp port 53" -T fields -e dns.id -e dns.flags.response -e dns.flags.rcode -e dns.qry.name -e dns.a'
on laptop 'dig +short www.example.com; dig +short nosuch.example.com'
fg
bg laptop 'tshark -n -i eth0 -c 2 -f "udp port 53" -O dns 2>/dev/null | sed -n "/^Frame 2/,/Authority RRs/p"'
lab exec laptop ana 'dig +short nosuch.example.com' >/dev/null 2>&1
fg

block tls-good
bg laptop 'tshark -n -i eth0 -c 12 -f "host 192.0.2.21 and tcp port 443" -Y tls'
on laptop "curl -sS $R https://www.example.com/"
fg

block tls-expired
bg laptop 'tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 8443" -Y tls -d tcp.port==8443,tls'
on laptop "curl -sS $R https://www.example.com:8443/"
fg

block tls-name
bg laptop 'tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 9443" -Y tls -d tcp.port==9443,tls'
on laptop "curl -sS $R https://www.example.com:9443/"
fg

block tls-ca
bg laptop 'tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 10443" -Y tls -d tcp.port==10443,tls'
on laptop "curl -sS $R https://www.example.com:10443/"
fg

block s_client
on laptop 'openssl s_client -connect 192.0.2.21:8443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|issuer=|NotAfter|Verify return code"'
on laptop 'openssl s_client -connect 192.0.2.21:9443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|Verify return code"'
on laptop 'openssl s_client -connect 192.0.2.21:10443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|issuer=|Verify return code"'

block file
BG_WAIT=2 bg laptop 'tshark -n -q -i eth0 -a duration:4 -f "host 192.0.2.21" -w failing.pcap'
lab exec laptop ana "curl -s $R https://www.example.com:8443/" >/dev/null 2>&1
fg
on laptop 'tshark -r failing.pcap'
