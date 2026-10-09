#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of networks-availability, as a
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
# (lesson 1), as network namespaces on one Linux computer.
#
# WHAT THE STUDENT DOES THAT A TRANSCRIPT DOES NOT SHOW, and where the lesson
# gives it. The two OpenVPN files are EXTRACTED from the lesson's examples
# with `lab.sh example`, and every command the lesson gives in an sh fence is
# extracted with `lab.sh fence` and run as ana with sudo, as the student types
# it: the certificates copied and the server started (tls-vpn), the client
# started and left running (handshake), the home router's firewall and the two
# files moved to TCP 443 (port-443), and branch's end of VXLAN (vxlan). The
# commands given inline in the prose are the `prose` lines below, word for
# word: stopping a program with netlab.sh kill, typed on the computer itself.
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
block() { printf '##### %s\n' "$1"; }
HERE=$(cd "$(dirname "$0")" && pwd)
# prose HOST 'command': a command the lesson gives in its text; its output is
# not quoted there.
prose() { local h=$1; shift; lab exec "$h" ana "$*" >/dev/null 2>&1 || true; }
# fence HOST FILE N: the Nth sh fence of FILE, typed on HOST.
fence() { prose "$1" "$(bash "$LAB_SH" fence "$HERE/$2" "$3")"; }
# vm 'command': typed on the computer itself, in ana's home.
vm() { ( cd ~ && bash -c "$*" ) >/dev/null 2>&1 || true; }

lab reset
bash "$LAB_SH" example "$HERE/tls-vpn.md" server.conf | lab exec hq root 'cat > /etc/openvpn/server.conf'
bash "$LAB_SH" example "$HERE/tls-vpn.md" client.conf | lab exec remote root 'cat > /etc/openvpn/client.conf'
fence hq tls-vpn.md 1
fence remote tls-vpn.md 2
sleep 1

block configs
on hq 'cat /etc/openvpn/server.conf'
on remote 'cat /etc/openvpn/client.conf'

block handshake
bg isp 'tshark -n -i eth0 -c 12 -f "udp port 1194"'
on remote 'cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "VERIFY OK|Control Channel:|Data Channel:|Initialization"'
fg

block tunnel-up
fence remote handshake.md 1
sleep 4
on remote 'ip -br addr show tun0; ip route | grep tun0'
on remote 'curl -s http://192.168.10.10/'
vm 'sudo bash netlab.sh kill remote openvpn'; sleep 0.5

block blocked
fence homegw port-443.md 1
on homegw 'sudo nft list chain ip filter forward'
on remote 'cd /etc/openvpn && sudo timeout 8 openvpn --config client.conf | grep -E "link remote|Initialization"'

block tcp443
vm 'sudo bash netlab.sh kill hq openvpn'; sleep 0.5
fence hq port-443.md 2
fence remote port-443.md 3
sleep 1
on remote 'cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "TCP connection|Peer Connection|Initialization"'

block vxlan
on hq 'sudo ip link add vx0 type vxlan id 100 local 203.0.113.2 remote 198.51.100.2 dstport 4789 dev eth1'
on hq 'sudo ip addr add 172.16.0.1/24 dev vx0 && sudo ip link set vx0 up'
fence branch vxlan.md 1
on hq 'ip link show vx0'
bg isp 'sudo tcpdump -n -t -e -i eth0 -c 4 udp port 4789'
on hq 'ping -c 1 172.16.0.2'
fg
on hq 'ip neigh show dev vx0; bridge fdb show dev vx0'
