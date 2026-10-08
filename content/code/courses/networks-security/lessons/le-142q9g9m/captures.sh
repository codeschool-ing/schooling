#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo ln -sf "$(realpath ../../lab.sh)" /var/tmp/nslab.sh   # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@sensor is the administrator on the intrusion detection sensor plugged
# into the DMZ with no address of its own; it is the defender's instrument, and
# every packet it records crossed the company's own segment.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; the recording on sensor, tcpdump -i eth0 -w, started in the
# background before each recording block and stopped after it, the lesson
# showing it being read; printer, a device plugged into the staff LAN with
# lab.sh plug and configured by mistake with desk's address, 192.168.10.21,
# the ordinary way two machines end up claiming one address.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/nslab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset
quiet fw 'nft -f baseline.nft'
record() { quiet sensor "setsid timeout 8 tcpdump -i eth0 -s0 -w /root/$1.pcap $2 </dev/null >/dev/null 2>&1 &"; sleep 2; }
stop() { sleep 1; quiet sensor 'pkill -INT -x tcpdump; sleep 1'; }

block sensor
root sensor 'ip -br addr show eth0'

block cleartext
record http 'tcp port 80'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" -b "session=7f3a9c2e" http://www.example.com/orders'
stop
root sensor 'tcpdump -r http.pcap -n -A 2>/dev/null | grep -aoE "GET /[^ ]* HTTP/1.1|Host: .*|User-Agent: .*|Cookie: .*" | uniq'

block dns
record dns 'udp port 53'
on remote 'dig +short @192.0.2.53 www.example.com'
stop
root sensor 'tcpdump -r dns.pcap -n 2>/dev/null | cut -d" " -f2-'

block tls
record tls 'tcp port 443'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" -b "session=7f3a9c2e" https://www.example.com/orders'
stop
root sensor 'tcpdump -r tls.pcap -n -A 2>/dev/null | grep -caE "GET /|Cookie: "'
root sensor 'tcpdump -r tls.pcap -n 2>/dev/null | wc -l'

block neighbours
on laptop 'ip neigh show dev eth0'
on laptop 'arping -c 2 -I eth0 192.168.10.1'

block conflict
lab plug printer lan 192.168.10.21/24 52:54:00:0a:77:21 >/dev/null 2>&1
on laptop 'arping -c 3 -I eth0 192.168.10.21'

block dad
root sensor 'arping -D -c 2 -I eth0 192.0.2.80; echo "exit $?"'
root sensor 'arping -D -c 2 -I eth0 192.0.2.81; echo "exit $?"'

block static
root laptop 'ip neigh replace 192.168.10.1 lladdr 52:54:00:a8:0a:01 dev eth0 nud permanent; ip neigh show 192.168.10.1'
on laptop 'curl -s https://www.example.com/'
