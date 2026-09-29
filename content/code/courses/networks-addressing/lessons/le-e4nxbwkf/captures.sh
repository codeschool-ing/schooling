#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of networks-addressing, as a script
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
# The lab is lab.sh's "intervlan" scenario: the switch sw1 with pc1 and srv in
# VLAN 10 and pc2 in VLAN 20, configured as lesson 19 taught, and the router
# r1 on port p8, a trunk carrying both VLANs. srv runs a web server on port
# 80. The router starts with no address; the lesson types them.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up intervlan`; and, before the layer-3 switch block, r1
# unplugged from the switch (the script sets r1's end of the cable down), so
# the switch is the only router left.
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

lab up intervlan

block no-router
root sw1 'bridge vlan show'
on pc1 'ping -c 1 -W 1 -q 10.20.10.10'
on pc1 'ping -c 1 -W 1 10.20.20.22'
on pc1 'ip neigh'

block stick
root r1 'ip link add link eth0 name eth0.10 type vlan id 10'
root r1 'ip link add link eth0 name eth0.20 type vlan id 20'
root r1 'ip addr add 10.20.10.1/24 dev eth0.10 && ip addr add 10.20.20.1/24 dev eth0.20'
root r1 'ip link set eth0.10 up && ip link set eth0.20 up'
root r1 'ip -br addr'
root r1 'ip route'
on pc1 'ping -c 2 -q 10.20.20.22'
on pc1 'traceroute -n 10.20.20.22'
on pc2 'curl -s http://10.20.10.10/'

block twice
bgon root sw1 'timeout 6 tcpdump -n -e -i p8 -c 4 icmp'
on pc1 'ping -c 1 -q 10.20.20.22'
fgon

block missing-vlan
root sw1 'bridge vlan del dev p8 vid 20'
on pc2 'ping -c 2 -W 1 -q 10.20.20.1'
on pc2 'ip neigh'
root sw1 'bridge vlan show dev p8'
root sw1 'bridge vlan add dev p8 vid 20'
on pc2 'ping -c 2 -q 10.20.20.1'

block l3-switch
quiet r1 'ip link set eth0 down'
on pc1 'ping -c 1 -W 1 -q 10.20.20.22'
root sw1 'ip link add link br0 name vlan10 type vlan id 10'
root sw1 'ip link add link br0 name vlan20 type vlan id 20'
root sw1 'bridge vlan add dev br0 vid 10 self && bridge vlan add dev br0 vid 20 self'
root sw1 'ip addr add 10.20.10.1/24 dev vlan10 && ip addr add 10.20.20.1/24 dev vlan20'
root sw1 'ip link set vlan10 up && ip link set vlan20 up && sysctl -w net.ipv4.ip_forward=1'
root sw1 'ip route'
on pc1 'ping -c 2 -q 10.20.20.22'
on pc1 'ip neigh show 10.20.10.1'
root sw1 'ip -br link show vlan10'
root sw1 'arping -U -c 1 -I vlan10 10.20.10.1'
on pc1 'ip neigh show 10.20.10.1'
on pc1 'ping -c 2 -q 10.20.20.22'
on pc1 'traceroute -n 10.20.20.22'

block acl
root sw1 'nft add table inet acl'
root sw1 'nft add chain inet acl forward "{ type filter hook forward priority 0; policy accept; }"'
root sw1 'nft add rule inet acl forward ct state established,related accept'
root sw1 'nft add rule inet acl forward iifname "vlan20" oifname "vlan10" ip daddr 10.20.10.10 tcp dport 80 accept'
root sw1 'nft add rule inet acl forward iifname "vlan20" oifname "vlan10" counter drop'
on pc2 'curl -s -m 3 http://10.20.10.10/'
on pc2 'ping -c 2 -W 1 -q 10.20.10.21'
on pc1 'ping -c 2 -q 10.20.20.22'
root sw1 'nft list table inet acl'
