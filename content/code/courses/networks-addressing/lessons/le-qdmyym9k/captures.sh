#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# The lab is lab.sh's "sites" scenario: a head office (pc1 behind the router
# rhq) and a branch (pc2 behind rbr), each on its own LAN, joined only by the
# provider isp. A line that starts with ana@pc1 ran on pc1; root@rhq is the
# head office's router at a root prompt.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab,
# built by `lab.sh up sites`, and the two WireGuard private keys, which lab.sh
# writes to /run/lab/rhq/wg.key and /run/lab/rbr/wg.key. Everything the lesson
# shows being configured on the routers was typed at their prompts.
#
# Recorded on Ubuntu 24.04 in a virtual machine, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-$(cd "$(dirname "$0")/../.." && pwd)/lab.sh}
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

lab up sites

block lan
on pc1 'ip -br addr show eth0'
on pc1 'ip route'
on pc2 'ip -br addr show eth0'

block wan
on pc1 'traceroute -n 198.51.100.2'
root isp 'ip route'

block no-vpn
on pc1 'ping -c 2 10.30.10.22'

block vpn-config
root rhq 'ip link add wg0 type wireguard'
root rhq 'wg set wg0 listen-port 51820 private-key /run/lab/rhq/wg.key peer +JFzEjDfzTBIMYnsaG9+qGoe12VEnNzYlLvJ6Ftnojo= endpoint 198.51.100.2:51820 allowed-ips 10.30.10.0/24,10.255.255.2/32'
root rhq 'ip addr add 10.255.255.1/30 dev wg0 && ip link set wg0 up && ip route add 10.30.10.0/24 dev wg0'
root rbr 'ip link add wg0 type wireguard'
root rbr 'wg set wg0 listen-port 51820 private-key /run/lab/rbr/wg.key peer PLKSQ+aPlVn+/rt1DVIP+p5D0RVtQLLwMulg682GHiA= endpoint 203.0.113.2:51820 allowed-ips 10.20.10.0/24,10.255.255.1/32'
root rbr 'ip addr add 10.255.255.2/30 dev wg0 && ip link set wg0 up && ip route add 10.20.10.0/24 dev wg0'

block vpn-use
on pc1 'ping -c 2 10.30.10.22'
on pc1 'traceroute -n 10.30.10.22'
root rhq 'wg show'

block vpn-wire
bgon root isp 'timeout 6 tcpdump -n -c 4 -i eth0'
on pc1 'ping -c 2 10.30.10.22'
fgon
bgon root rhq 'timeout 6 tcpdump -n -c 4 -i wg0'
on pc1 'ping -c 2 10.30.10.22'
fgon
