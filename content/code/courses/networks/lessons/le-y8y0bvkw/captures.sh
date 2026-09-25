#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of networks, as a script that produces them.
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
# the lab itself, built by lab.sh reset; a 200 kB text file written into the
# web server's folder, so a page needs many full-sized packets; before the
# pmtu block, the MTU of the link between router and isp lowered to 1492 on
# both ends; and before the blackhole block, a rule on isp that drops the ICMP
# 'destination unreachable' messages it would send, and the route caches of
# laptop and www emptied so neither remembers the smaller MTU.
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

# A command left running on a machine while others work, the way a second
# terminal would be: its prompt and output are printed when collected.
later() {
  printf 'ana@%s:~$ %s\n' "$2" "$3" > "/tmp/later.$1"
  lab exec "$2" ana "$3" >> "/tmp/later.$1" 2>&1 &
  eval "LATER_$1=$!"
  sleep 1.5
}
collect() { eval "wait \$LATER_$1"; cat "/tmp/later.$1"; rm -f "/tmp/later.$1"; }

lab reset
# A page big enough to need many full-sized packets: 200 kB of text.
quiet www 'for i in $(seq 1 2000); do echo "line $i of the price list, padded to a hundred characters so the file is large enough ....."; done > /var/www/example/prices.txt'

block socket
on laptop 'strace -f -e trace=socket,connect curl -s -o /dev/null http://www.example.com/'

block ports
on laptop 'cat /proc/sys/net/ipv4/ip_local_port_range'

block two-links
later lan laptop 'sudo tcpdump -n -e -v -c 2 -i eth0 icmp'
later wan router 'sudo tcpdump -n -e -v -c 2 -i eth1 icmp'
on laptop 'ping -c 1 192.0.2.80'
block two-links-lan
collect lan
block two-links-wan
collect wan

block nat
on router 'sudo nft list ruleset'
lab exec laptop ana 'curl -s -o /dev/null https://www.example.com/' >/dev/null 2>&1
on www 'tail -1 /var/log/nginx/access.log'

block mss
later syn laptop 'sudo tcpdump -n -c 2 -i eth0 "tcp[tcpflags] & tcp-syn != 0"'
lab exec laptop ana 'curl -s -o /dev/null https://www.example.com/' >/dev/null 2>&1
collect syn

block mtu-lan
on laptop 'ip link show eth0 | head -1'
on laptop 'ping -c 1 -M do -s 1472 192.0.2.80'
on laptop 'ping -c 1 -M do -s 1473 192.0.2.80'

# The provider's line now carries 1492 bytes, as a DSL line with PPPoE does.
quiet router 'ip link set eth1 mtu 1492'
quiet isp 'ip link set eth0 mtu 1492'

block pmtu
on laptop 'ping -c 2 -M do -s 1472 192.0.2.80'
on laptop 'ip route get 192.0.2.80'
on laptop 'tracepath -n 192.0.2.80'

block blackhole
# ... and the provider's router stops sending the ICMP that says so.
quiet isp 'nft add table inet f; nft add chain inet f out "{ type filter hook output priority 0; }"; nft add rule inet f out icmp type destination-unreachable drop'
quiet laptop 'ip route flush cache'
quiet www 'ip route flush cache'
on laptop "curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/"
on laptop "curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/prices.txt"

block clamp
on router 'sudo nft add table inet mangle'
on router "sudo nft add chain inet mangle forward '{ type filter hook forward priority mangle; }'"
on router 'sudo nft add rule inet mangle forward tcp flags syn tcp option maxseg size set rt mtu'
on router 'sudo nft list table inet mangle'
on laptop "curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/prices.txt"

block clamp-syn
later syn2 www 'sudo tcpdump -n -c 1 -i eth0 "tcp[tcpflags] == tcp-syn"'
lab exec laptop ana 'curl -s -o /dev/null https://www.example.com/' >/dev/null 2>&1
collect syn2

lab down
