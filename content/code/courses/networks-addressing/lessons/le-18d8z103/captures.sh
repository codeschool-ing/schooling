#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of networks-addressing, as a script
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
# The lab is lab.sh's "dhcp" scenario: pc1, pc2, the printer prn, a PC called
# rogue and the server srv on the switch sw1, and the router r1 with a second
# floor, pc4, on its own subnet. srv runs ISC dhcpd with the configuration
# the lesson prints. Every PC starts with no IPv4 address.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up dhcp`; pc2's lease released before each capture of
# its DHCP exchange, so it starts from nothing; and, for the rogue block, a second DHCP server
# started on rogue by `lab.sh rogue`, which hands out 10.20.10.200 upwards
# and names 10.20.10.66 as the gateway. The lesson shows what it does and
# how the switch stops it, never how to build one.
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

lab up dhcp

block before
on pc1 'ip -br addr show eth0'
on pc1 'ip route'

block dora
bgon root srv 'timeout 15 tcpdump -n -i eth0 -c 4 port 67 or port 68'
on pc1 'sudo dhclient -v eth0'
fgon
on pc1 'ip -br addr show eth0'
on pc1 'ip route'
on pc1 'cat /etc/resolv.conf'

block scope
root srv 'cat /run/lab/srv/dhcpd.conf'
on pc2 'sudo dhclient eth0 && ip -br addr show eth0'

block reservation
on prn 'ip link show eth0 | grep ether'
on prn 'sudo dhclient -v eth0 2>&1 | grep -E "DHCP|bound"'
on prn 'ip -br addr show eth0'

block leases
root srv 'cat /var/lib/dhcp/dhcpd.leases'
on pc1 'cat /var/lib/dhcp/dhclient.leases'
on pc2 'sudo dhclient -r -v eth0 2>&1 | grep -E "DHCP"'
on pc2 'ip -br addr show eth0'

block relay
on pc4 'sudo timeout 12 dhclient -v -1 eth0 2>&1 | grep -E "DHCP|bound|No"'
root r1 'dhcrelay -4 -iu eth0 -id eth2 10.20.10.10'
bgon root srv 'timeout 15 tcpdump -n -i eth0 -c 4 port 67'
on pc4 'sudo dhclient -v eth0 2>&1 | grep -E "DHCP|bound"'
fgon
on pc4 'ip route'

block rogue
lab rogue >/dev/null 2>&1
sleep 3
quiet pc2 'dhclient -r eth0'
bgon root pc2 'timeout 12 tcpdump -n -i eth0 udp src port 67'
on pc2 'sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"'
fgon
root srv 'kill -STOP $(cat /run/lab/srv/dhcpd.pidfile)'
on pc2 'sudo dhclient -r eth0; sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"'
on pc2 'ip route'
on pc2 'ping -c 2 -W 1 10.20.20.1'
root srv 'kill -CONT $(cat /run/lab/srv/dhcpd.pidfile)'

block snooping
root sw1 'nft add table bridge snoop'
root sw1 'nft add chain bridge snoop forward "{ type filter hook forward priority 0; }"'
root sw1 'nft add rule bridge snoop forward iifname != "p4" udp sport 67 counter drop'
quiet pc2 'dhclient -r eth0'
bgon root pc2 'timeout 12 tcpdump -n -i eth0 udp src port 67'
on pc2 'sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"'
fgon
on pc2 'ip route'
root sw1 'nft list table bridge snoop'
