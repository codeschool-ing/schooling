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
#   sudo cp ../../lab.sh /var/tmp/lab.sh  # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds a head office
# (hq), a branch, a home, an ISP and a small data centre out of network
# namespaces on one Linux computer. A line that starts with ana@hq ran on the
# machine called hq, and so on.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset. The tunnel program, /usr/local/bin/tunnel.py,
# is installed by the lab because this kernel has no GRE and no IP-in-IP
# module; it is started here in the foreground of a shown command, and each
# tunnel is stopped (by pid, as root) before the next one is built.
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
  ( timeout -s INT 40 sudo bash "$LAB_SH" exec "$h" ana "$*" >> "$BG/out" 2>&1 || true ) &
  echo $! > "$BG/pid"
  sleep "${BG_WAIT:-1.5}"
}
fg() { wait "$(cat "$BG/pid")" 2>/dev/null || true; cat "$BG/out"; }
block() { printf '##### %s\n' "$1"; }
stop_tunnels() {
  for h in hq branch; do
    lab kill "$h" tunnel.py
  done
  sleep 0.5
}

lab reset

block no-route
on laptop 'ping -c 2 -W 1 192.168.20.30'
on laptop 'traceroute -n -w 1 -q 1 -m 4 192.168.20.30'
on isp 'ip route'

block ipip-up
on hq 'sudo setsid tunnel.py ipip tun0 203.0.113.2 198.51.100.2 & sleep 1; ip -br link show tun0'
on hq 'sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1480 up'
on hq 'sudo ip route add 192.168.20.0/24 via 10.0.0.2'
quiet branch 'setsid tunnel.py ipip tun0 198.51.100.2 203.0.113.2 </dev/null >/dev/null 2>&1 & sleep 1; ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0; ip link set tun0 mtu 1480 up; ip route add 192.168.10.0/24 via 10.0.0.1'
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
stop_tunnels
quiet hq 'ip route del 192.168.20.0/24'
quiet branch 'ip route del 192.168.10.0/24'
on hq 'sudo setsid tunnel.py gre tun0 203.0.113.2 198.51.100.2 42 & sleep 1; sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.20.0/24 via 10.0.0.2'
quiet branch 'setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 </dev/null >/dev/null 2>&1 & sleep 1; ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0; ip link set tun0 mtu 1472 up; ip route add 192.168.10.0/24 via 10.0.0.1'
bg isp 'sudo tcpdump -n -t -v -i eth0 -c 2 ip proto 47'
lab exec laptop ana 'ping -c 1 192.168.20.30' >/dev/null 2>&1
fg

block gre-key
lab kill branch tunnel.py; sleep 0.5
quiet branch 'setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 43 </dev/null >/dev/null 2>&1 & sleep 1; ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0; ip link set tun0 mtu 1472 up; ip route add 192.168.10.0/24 via 10.0.0.1'
on laptop 'ping -c 2 -W 1 192.168.20.30'
lab kill branch tunnel.py; sleep 0.5
quiet branch 'setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 </dev/null >/dev/null 2>&1 & sleep 1; ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0; ip link set tun0 mtu 1472 up; ip route add 192.168.10.0/24 via 10.0.0.1'
on laptop 'ping -c 1 192.168.20.30'

block plaintext
bg isp 'sudo tcpdump -l -n -t -A -i eth0 -c 8 ip proto 47 | grep --line-buffered -E "GRE|GET|Host|served"'
lab exec till ana 'curl -s http://192.168.10.10/' >/dev/null 2>&1
fg

block overhead
on hq 'ip link show tun0; ip link show eth1'

stop_tunnels
