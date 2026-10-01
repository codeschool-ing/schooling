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
#   sudo cp ../../lab.sh /var/tmp/lab.sh  # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh: a head
# office (hq), a branch, a home behind its own NAT, an ISP and a small data
# centre, as network namespaces on one Linux computer.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the certificates, made by lab.sh from the
# lab's own certificate authority and copied into /etc/openvpn on hq and on
# remote; the two OpenVPN configuration files, written below as root (the
# lesson shows them with cat); the OpenVPN server on hq, started as root and
# restarted when its configuration changes; the home router's firewall rule
# that lets only TCP 443 out, added as root before the tcp block.
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
server() {  # server PROTO PORT
  lab kill hq 'openvpn --config' ; sleep 0.5
  lab exec hq root "cat > /etc/openvpn/server.conf" <<C
dev tun
proto $1
port $2
server 10.8.0.0 255.255.255.0
topology subnet
ca ca.crt
cert vpn-server.crt
key vpn-server.key
dh none
push "route 192.168.10.0 255.255.255.0"
keepalive 10 60
C
  quiet hq 'cd /etc/openvpn && setsid openvpn --config server.conf </dev/null >/run/openvpn.log 2>&1 &'
  sleep 1
}
client() {  # client PROTO PORT
  lab exec remote root "cat > /etc/openvpn/client.conf" <<C
client
dev tun
proto $1
remote vpn.example.com $2
ca ca.crt
cert vpn-ana.crt
key vpn-ana.key
remote-cert-tls server
verify-x509-name vpn.example.com name
verb 3
C
}

lab reset
quiet hq 'cp /lab/tls/ca.crt /lab/tls/vpn-server.crt /lab/tls/vpn-server.key /etc/openvpn/; chmod 600 /etc/openvpn/vpn-server.key'
quiet remote 'cp /lab/tls/ca.crt /lab/tls/vpn-ana.crt /lab/tls/vpn-ana.key /etc/openvpn/; chmod 600 /etc/openvpn/vpn-ana.key'
server udp 1194
client udp 1194

block configs
on hq 'cat /etc/openvpn/server.conf'
on remote 'cat /etc/openvpn/client.conf'

block handshake
bg isp 'tshark -n -i eth0 -c 12 -f "udp port 1194"'
on remote 'cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "VERIFY OK|Control Channel:|Data Channel:|Initialization"'
fg

block tunnel-up
quiet remote 'cd /etc/openvpn && setsid openvpn --config client.conf </dev/null >/run/openvpn.log 2>&1 &'
sleep 4
on remote 'ip -br addr show tun0; ip route | grep tun0'
on remote 'curl -s http://192.168.10.10/'
lab kill remote 'openvpn --config'; sleep 0.5

block blocked
quiet homegw 'nft add table ip filter; nft add chain ip filter forward "{ type filter hook forward priority 0; policy drop; }"; nft add rule ip filter forward ct state established,related accept; nft add rule ip filter forward iifname eth0 tcp dport 443 accept; nft add rule ip filter forward iifname eth0 udp dport 53 accept'
on homegw 'sudo nft list chain ip filter forward'
on remote 'cd /etc/openvpn && sudo timeout 8 openvpn --config client.conf | grep -E "link remote|Initialization"'

block tcp443
server tcp-server 443
client tcp-client 443
on remote 'cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "TCP connection|Peer Connection|Initialization"'

block vxlan
on hq 'sudo ip link add vx0 type vxlan id 100 local 203.0.113.2 remote 198.51.100.2 dstport 4789 dev eth1'
on hq 'sudo ip addr add 172.16.0.1/24 dev vx0 && sudo ip link set vx0 up'
quiet branch 'ip link add vx0 type vxlan id 100 local 198.51.100.2 remote 203.0.113.2 dstport 4789 dev eth1; ip addr add 172.16.0.2/24 dev vx0; ip link set vx0 up'
on hq 'ip link show vx0'
bg isp 'sudo tcpdump -n -t -e -i eth0 -c 4 udp port 4789'
on hq 'ping -c 1 172.16.0.2'
fg
on hq 'ip neigh show dev vx0; bridge fdb show dev vx0'
