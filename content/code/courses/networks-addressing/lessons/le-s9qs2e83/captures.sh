#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of networks-addressing, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh       # on the machine ../../lab.sh describes; it runs
#                               # the lab files the lessons show, copied out of them
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds the "office"
# scenario out of network namespaces on one Linux computer: four PCs on a
# switch, a router that is also the firewall, a provider, and a load balancer
# in front of two web servers. A line that starts with ana@pc1 ran on the
# machine called pc1; root@r1 is the router, at a root prompt.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by `lab.sh up office`; the switch's MAC table and every
# neighbour table emptied before the switch block, so the table fills in front
# of the reader; the switch turned into a hub for the hub block by setting its
# ageing time to zero, which makes it forget every address as soon as it
# learns it and so flood every frame, and back afterwards; a route on the
# provider towards the office's private network for the firewall block, so the
# only thing refusing the connection is the firewall.
#
# THE SETUP SECTIONS ARE A SEPARATE RUN, on a machine made fresh from the
# cloud image with nothing installed: `sudo bash captures.sh setup`. It copies
# the lab files out of the lessons into ~ana/netlab, as a student would have
# saved them, and types what the sections show, failures first. The package
# line it installs with is read out of the lesson too, from the first fence of
# netlab.md. The block fail-modules is not here: it was recorded in a Linux
# container (kernel 6.18.44-fc-v77, no /lib/modules) by typing
# `sudo bash ~/netlab/netlab.sh up office` as ana, and no VM can reproduce it.
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
# here 'command': typed on the machine itself, outside any device
here() { printf 'ana@lab:~$ %s\n' "$*"; runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $*" 2>&1 || true; }

if [ "${1:-}" = setup ]; then
  lab list >/dev/null
  rm -rf /home/ana/netlab; cp -r "${NETLAB:-/var/tmp/netlab}" /home/ana/netlab; chown -R ana: /home/ana/netlab
  block fail-sudo
  here 'bash ~/netlab/netlab.sh up office'
  block fail-packages
  here 'sudo bash ~/netlab/netlab.sh up office'
  # the package line of netlab.md, as the student runs it
  awk '/^```sh$/{f=1;next} f&&/^```$/{exit} f' "$(dirname "$0")/netlab.md" > /tmp/packages.sh
  runuser -u ana -- bash /tmp/packages.sh >/dev/null 2>&1 || { echo "the package line failed" >&2; exit 1; }
  block setup-up
  here 'sudo bash ~/netlab/netlab.sh up office'
  block setup-on
  here "sudo bash ~/netlab/netlab.sh on pc1 \"\$USER\" 'ping -c 2 srv'"
  block fail-names
  here 'sudo bash ~/netlab/netlab.sh up offce'
  here 'bash ~/netlab/netlab.sh list'
  here 'sudo bash ~/netlab/netlab.sh down'
  here 'sudo bash ~/netlab/netlab.sh on pc1'
  block fail-short
  # office.sh pasted without its last lines: the first 40 of them
  cp /home/ana/netlab/office.sh /tmp/office.whole; head -n 40 /tmp/office.whole > /home/ana/netlab/office.sh
  here 'bash -n ~/netlab/office.sh'
  here 'sudo bash ~/netlab/netlab.sh up office'
  cp /tmp/office.whole /home/ana/netlab/office.sh
  exit 0
fi

lab up office

block switch
for h in pc1 pc2 pc3 srv r1; do quiet $h 'ip neigh flush all'; done
quiet sw1 'bridge fdb flush dev br0 dynamic; for p in p1 p2 p3 p4 p8; do bridge fdb flush dev $p dynamic; done'
root sw1 'bridge link show'
root sw1 'bridge fdb show br br0 dynamic'
on pc1 'ping -c 2 10.20.10.22'
root sw1 'bridge fdb show br br0 dynamic'

block switch-listen
bgon root pc3 'timeout 6 tcpdump -n -e -i eth0 icmp'
on pc1 'ping -c 3 10.20.10.22'
fgon

block hub
quiet sw1 'ip link set br0 type bridge ageing_time 0'
root sw1 'ip -d link show br0 | grep -o "ageing_time [0-9]*"'
bgon root pc3 'timeout 6 tcpdump -n -e -i eth0 icmp'
on pc1 'ping -c 3 10.20.10.22'
fgon
quiet sw1 'ip link set br0 type bridge ageing_time 30000'

block router
root r1 'ip -br addr'
root r1 'ip route'
root r1 'sysctl net.ipv4.ip_forward'
on pc1 'ping -c 1 10.20.10.10'
on pc1 'ping -c 1 192.0.2.80'
on pc1 'traceroute -n 192.0.2.80'

block firewall
quiet isp 'ip route add 10.20.10.0/24 via 203.0.113.2'
root r1 'nft list chain inet filter forward'
on pc1 'curl -s http://192.0.2.80/'
root isp 'curl -s -m 5 http://10.20.10.10/; echo "exit status $?"'
root r1 'nft list chain inet filter forward'

block lb
root lb 'nft list table ip lb'
on pc1 'for i in 1 2 3 4; do curl -s http://192.0.2.80/; done'
on pc2 'curl -s http://192.0.2.80/'
root web1 'ip -br addr show eth0'
