#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of networks-availability, as a
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
# EVERY MACHINE IN THE LESSON IS PART OF ONE NETWORK, the one netlab.sh builds
# out of network namespaces on one Linux computer. A line that starts with
# ana@hq ran on the machine called hq, and so on; a line that starts with
# ana@netlab ran on the computer itself, which the student's virtual machine
# is named after.
#
# NOTHING IS STAGED BEHIND THE STUDENT'S BACK. The network is built by
# `lab reset` before the first block, which the section "Building the network"
# has the student do with `sudo bash netlab.sh up`; that section's own
# transcript is the block called setup, recorded on a fresh network. Every
# command after it, on every machine, is shown in the lesson.
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
# vm 'command': what ana typed on the computer itself, in her home directory.
vm() { printf 'ana@netlab:~$ %s\n' "$*"; ( cd ~ && bash -c "$*" ) 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab install
lab down >/dev/null 2>&1 || true

block setup
vm 'sudo bash netlab.sh up'
vm 'ip netns list'
# A shell prints nothing but its prompt, so the line that opens it is printed
# and the commands typed in it are run the way on() runs every other one. It
# was opened for real, with a terminal, while this was written: its prompt is
# ana@laptop:~$, as below.
printf 'ana@netlab:~$ %s\n' 'sudo bash netlab.sh shell laptop'
on laptop 'ip -br addr'
on laptop 'ping -c 1 web1.example.com'

lab reset

block no-route
on laptop 'ping -c 2 -W 1 192.168.20.30'
on laptop 'traceroute -n -w 1 -q 1 -m 4 192.168.20.30'
on isp 'ip route'

block ipip-up
on hq 'sudo setsid tunnel.py ipip tun0 203.0.113.2 198.51.100.2 & sleep 1; ip -br link show tun0'
on hq 'sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1480 up'
on hq 'sudo ip route add 192.168.20.0/24 via 10.0.0.2'
on branch 'sudo setsid tunnel.py ipip tun0 198.51.100.2 203.0.113.2 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1480 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1'
on branch 'ip route'
on laptop 'ping -c 2 192.168.20.30'

block ipip-wire
bg isp 'sudo tcpdump -n -t -i eth0 -c 2 ip proto 4'
lab exec laptop ana 'ping -c 1 192.168.20.30' >/dev/null 2>&1
fg
bg isp 'sudo tcpdump -n -t -v -i eth0 -c 1 ip proto 4'
lab exec laptop ana 'ping -c 1 192.168.20.30' >/dev/null 2>&1
fg

block mtu
on laptop 'ping -c 1 -M do -s 1472 192.168.20.30'
on laptop 'ping -c 1 -M do -s 1452 192.168.20.30'
on laptop 'ip route get 192.168.20.30'

block kernel
on hq 'sudo ip link add gre1 type gre local 203.0.113.2 remote 198.51.100.2 key 42'

block gre-up
vm 'sudo bash netlab.sh kill hq tunnel.py; sudo bash netlab.sh kill branch tunnel.py'
sleep 0.5
on hq 'sudo setsid tunnel.py gre tun0 203.0.113.2 198.51.100.2 42 & sleep 1; sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.20.0/24 via 10.0.0.2'
on branch 'sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1'
bg isp 'sudo tcpdump -n -t -v -i eth0 -c 2 ip proto 47'
lab exec laptop ana 'ping -c 1 192.168.20.30' >/dev/null 2>&1
fg

block gre-key
vm 'sudo bash netlab.sh kill branch tunnel.py'
sleep 0.5
on branch 'sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 43 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1'
on laptop 'ping -c 2 -W 1 192.168.20.30'
vm 'sudo bash netlab.sh kill branch tunnel.py'
sleep 0.5
on branch 'sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1'
on laptop 'ping -c 1 192.168.20.30'

block plaintext
bg isp 'sudo tcpdump -l -n -t -A -i eth0 -c 8 ip proto 47 | grep --line-buffered -E "GRE|GET|Host|served"'
lab exec till ana 'curl -s http://192.168.10.10/' >/dev/null 2>&1
fg

block overhead
on hq 'ip link show tun0; ip link show eth1'

lab kill hq tunnel.py; lab kill branch tunnel.py
