#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of networks, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds an office, an
# ISP and a small internet out of network namespaces on one Linux computer,
# with its own DNS root and its own certificate authority. Nothing reaches the
# real internet, which is why the addresses and names are the ones reserved
# for documentation. A line that starts with ana@laptop ran on the machine
# called laptop, and so on.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, and the faults each ticket
# starts from, each set up by the lines just above its block: the laptop's
# default route removed; the laptop given a DNS server that does not exist;
# the ISP's router answering only about half of the probes that expire on
# it, as busy routers rate-limit them, and then core dropping one packet
# in five on the way to www; a printer plugged into the office with the
# server's address; and the web server stopped.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.

set -uo pipefail
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
block() { printf '##### %s\n' "$1"; }

later() {
  printf 'ana@%s:~$ %s\n' "$2" "$3" > "/tmp/later.$1"
  lab exec "$2" ana "$3" >> "/tmp/later.$1" 2>&1 &
  eval "LATER_$1=$!"
  sleep 1.5
}
collect() { eval "wait \$LATER_$1"; cat "/tmp/later.$1"; rm -f "/tmp/later.$1"; }

lab reset

block no-gateway
# The laptop loses its default route, as a hand-typed network setting would.
quiet laptop 'ip route del default'
on laptop 'ping -c 2 www.example.com'
on laptop 'ip -br addr show eth0'
on laptop 'ip route'
on laptop 'ping -c 2 192.168.10.1'
on laptop 'ping -c 2 192.0.2.80'
on laptop 'sudo ip route add default via 192.168.10.1'
on laptop 'ping -c 2 www.example.com'

block wrong-dns
# The laptop is given a DNS server that does not exist.
sudo sh -c 'printf "nameserver 192.168.10.53\n" > /etc/netns/laptop/resolv.conf'
on laptop 'curl -sS -m 30 https://www.example.com/ -o /dev/null'
on laptop 'ping -c 2 192.0.2.80'
on laptop 'cat /etc/resolv.conf'
later dns laptop 'sudo timeout 6 tcpdump -i eth0 -n -l arp or port 53 2>/dev/null'
on laptop 'dig +tries=1 +time=3 www.example.com'
collect dns
on laptop 'dig +short @198.51.100.53 www.example.com'
on laptop 'echo "nameserver 198.51.100.53" | sudo tee /etc/resolv.conf'
on laptop 'dig +short www.example.com'

block nslookup
on laptop 'nslookup www.example.com'
on laptop 'nslookup -type=mx example.net'
on laptop 'nslookup 192.0.2.80'

block traceroute
on laptop 'traceroute -n www.example.com'

block mtr
# The ISP's router answers only about half of the probes that expire on it,
# as a busy router rate-limits the messages it generates.
quiet isp 'nft add table inet slow; nft "add chain inet slow out { type filter hook output priority 0; }"; nft add rule inet slow out icmp type time-exceeded numgen random mod 2 == 0 drop'
on laptop 'mtr -rwn -c 20 www.example.com'
# And core now loses one packet in five on its way to www.
quiet core 'nft add table inet lossy; nft "add chain inet lossy lose { type filter hook forward priority 0; }"; nft add rule inet lossy lose ip daddr 192.0.2.80 numgen random mod 5 == 0 drop'
on laptop 'mtr -rwn -c 20 www.example.com'
quiet isp 'nft delete table inet slow'
quiet core 'nft delete table inet lossy'

block ss
on www 'sudo ss -tlnp'
later hold laptop 'sleep 4 | nc 192.0.2.80 80'
on laptop 'ss -tnp'
collect hold >/dev/null
on laptop 'netstat -tn'

block duplicate
# A new printer is plugged into the office network, set by hand to the
# address the server already has.
lab plug printer office 192.168.10.10/24 52:54:00:99:00:01
later arp laptop 'sudo timeout 4 tcpdump -i eth0 -n -e -l arp 2>/dev/null'
on laptop 'sudo ip neigh flush dev eth0; ping -c 1 192.168.10.10 >/dev/null; ip neigh show 192.168.10.10'
collect arp
on laptop 'nc -zv -w 3 192.168.10.10 22'

block pcap
sudo ip netns del printer
on laptop 'sudo ip neigh flush dev eth0'
later cap laptop 'sudo timeout 5 tcpdump -i eth0 -n -w /tmp/web.pcap host 192.0.2.80'
lab exec laptop ana 'curl -s https://www.example.com/ -o /dev/null' >/dev/null
collect cap
on laptop 'ls -l /tmp/web.pcap'
on laptop 'tcpdump -n -r /tmp/web.pcap "tcp[tcpflags] & (tcp-syn|tcp-fin) != 0" 2>/dev/null'

block refused
quiet www 'nginx -s stop'
on laptop 'curl -sS https://www.example.com/'
on www 'sudo ss -tlnp | grep -E ":(80|443) " || echo "nothing on 80 or 443"'
on www 'sudo nginx'
on laptop 'curl -sS -o /dev/null -w "%{http_code}\n" https://www.example.com/'

lab down >/dev/null 2>&1
