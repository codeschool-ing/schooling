#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of networks-availability, as a
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
# centre, as network namespaces on one Linux computer. mon is the analyst's
# machine, with one interface and no address.
#
# THERE IS NO SCREEN. Wireshark's window cannot be photographed here, so the
# lesson uses tshark, which is Wireshark's own engine with a terminal in front
# of it: the capture filters and the display filters below are typed exactly
# as they would be in the window's two filter bars.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the mirror port, set up with lab.sh span hq
# files before the span block, which copies files' port to mon's; and the
# traffic each capture catches, generated on files or laptop by the commands
# named beside each bg line below.
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
traffic() {  # the mix a morning on files produces, in miniature
  lab exec files ana 'curl -s http://192.0.2.21/ >/dev/null; dig +short www.example.com >/dev/null; dig +short nosuch.example.com >/dev/null; ping -c 2 192.0.2.22 >/dev/null; curl -s https://www.example.com/ --resolve www.example.com:443:192.0.2.21 >/dev/null; curl -s http://192.0.2.23/nothing-here >/dev/null' >/dev/null 2>&1
}

lab reset

block groups
on mon 'id -nG; tshark -D'

block switch
bg laptop 'sudo timeout 5 tcpdump -n -i eth0 host 192.168.10.10 and not host 192.168.10.20'
lab exec files ana 'curl -s http://192.0.2.21/' >/dev/null 2>&1
fg

block span
lab span hq files
bg mon 'tshark -n -i eth0 -c 6 -f "tcp port 80"'
lab exec files ana 'curl -s http://192.0.2.21/' >/dev/null 2>&1
fg

block write
BG_WAIT=2 bg mon 'tshark -n -q -i eth0 -f "not arp" -a duration:8 -w files.pcap'
traffic
fg
on mon 'ls -l files.pcap'
on mon 'tshark -r files.pcap | head -n 12'

block display
on mon 'tshark -r files.pcap -Y dns'
on mon 'tshark -r files.pcap -Y "http.request"'
on mon 'tshark -r files.pcap -Y "http.response.code >= 400"'
on mon 'tshark -r files.pcap -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0"'
on mon 'tshark -r files.pcap -Y "icmp && ip.dst == 192.0.2.22"'
on mon 'tshark -r files.pcap -Y "tls.handshake.type == 1" -T fields -e ip.dst -e tls.handshake.extensions_server_name'

block mistakes
on mon 'tshark -r files.pcap -Y "port 80"'
on mon 'tshark -r files.pcap -Y "ip.addr != 192.0.2.21" | wc -l'
on mon 'tshark -r files.pcap -Y "!(ip.addr == 192.0.2.21)" | wc -l'
on mon 'tshark -r files.pcap -Y "dns.qry.name == www.example.com" | head -n 2'
on mon 'tshark -r files.pcap -Y "http.request.uri contains \"nothing\""'

block follow
on mon 'tshark -r files.pcap -q -z follow,tcp,ascii,0'

block stats
on mon 'tshark -r files.pcap -q -z conv,ip'
on mon 'tshark -r files.pcap -q -z io,phs'
