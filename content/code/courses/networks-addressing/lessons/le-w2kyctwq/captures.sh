#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana       # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh    # the lab, beside course.json
#   sudo bash captures.sh
#
# The lab is lab.sh's "dualstack" scenario: pc1, pc2 and srv on one switch,
# the router r1 announcing 2001:db8:20:10::/64 with radvd, the provider isp,
# and a web server "web" outside that answers on 192.0.2.80 and on
# 2001:db8:99::80. The addresses are from the documentation blocks, 192.0.2.0/24
# and 2001:db8::/32. The PCs' IPv6 addresses were built by the PCs themselves.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up dualstack`, and a wait of ten seconds after it so the
# first router advertisement has reached every PC; the neighbour tables of pc1
# and srv emptied before the neighbour-discovery block. Duplicate address
# detection is switched off in the lab (lab.sh says why), so no address is
# ever caught "tentative".
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() { local h=$1; shift; printf 'ana@%s:~$ %s\n' "$h" "$*"; lab exec "$h" ana "$*" 2>&1 || true; }
# root HOST 'command': the same at a root prompt, on a device being configured.
root() { local h=$1; shift; printf 'root@%s:~# %s\n' "$h" "$*"; lab exec "$h" root "$*" 2>&1 || true; }
# quiet HOST 'command': the lab's own housekeeping, run as root and not shown.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while another does something, the way
# a second terminal would be: its prompt and output are printed when it ends.
bgon() {  # bgon USER HOST 'command'
  local p='$'; [ "$1" = root ] && p='#'
  printf '%s@%s:~%s %s\n' "$1" "$2" "$p" "$3" > /tmp/bg.out
  lab exec "$2" "$1" "$3" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep 2
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

lab up dualstack
sleep 10

block notation
on srv 'ip -6 addr show eth0'
on pc1 'sipcalc 2001:db8:20:10::10'
on pc1 'ping -c 1 2001:0db8:0020:0010:0000:0000:0000:0010'

block link-local
on pc1 'ip link show eth0'
on pc1 'ip -6 addr show eth0 scope link'
root r1 'ip -6 addr show eth0 scope link'
on pc1 'ping -c 1 fe80::1f:23ff:fee7:e9d5'
on pc1 'ping -c 1 fe80::1f:23ff:fee7:e9d5%eth0'

block slaac
on pc2 'rdisc6 eth0'
on pc2 'ip -6 addr show eth0 scope global'
on pc2 'ip -6 route'

block neighbour-discovery
quiet pc1 'ip -6 neigh flush all'; quiet srv 'ip -6 neigh flush all'
bgon root srv 'timeout 6 tcpdump -n -c 4 -i eth0 icmp6'
on pc1 'ping -c 1 2001:db8:20:10::10'
fgon
on pc1 'ip -6 neigh'
on pc1 'ping -w 2 ff02::1%eth0'

block dual-stack
on pc1 'ip -br addr show eth0'
on pc1 'getent ahosts web'
on pc1 'curl -s -4 http://web/ -w "%{remote_ip}\n"'
on pc1 'curl -s -6 http://web/ -w "%{remote_ip}\n"'

block no-nat
bgon root web 'timeout 8 tcpdump -n -c 4 -i eth0 "tcp[tcpflags] & tcp-syn != 0 or (ip6 and ip6[53] & 2 != 0)"'
on pc1 'curl -s -4 -o /dev/null http://web/'
on pc1 'curl -s -6 -o /dev/null http://web/'
fgon
