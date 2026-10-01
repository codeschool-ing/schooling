#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of networks-availability, as a
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
# EACH FAULT IS STAGED, AND THAT IS THE POINT OF THE LESSON: something is
# broken on purpose and the transcripts are the search for it. What is
# STAGED rather than typed, and not shown in the lesson:
#   - the lab itself, built by lab.sh reset;
#   - the cable: laptop's port on the office bridge set down, then up;
#   - the gateway: laptop's default route replaced with one via
#     192.168.10.99, an address nobody has, then put back;
#   - the resolver: laptop's /etc/resolv.conf pointed at 192.0.2.54, where
#     nothing answers, then put back;
#   - the service: web1's nginx stopped, then started;
#   - the worked case: a WireGuard tunnel between hq and branch, built as in
#     lesson 4, and a rule on hq that drops the ICMP messages it would send
#     back, which is the fault the case is about. The fix is typed and shown.
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
key() { lab exec "$1" root "umask 077; wg genkey > /etc/wireguard/key; wg pubkey < /etc/wireguard/key"; }
wgconf() { lab exec "$1" root "umask 077; sed \"s|PRIV|\$(cat /etc/wireguard/key)|\" > /etc/wireguard/wg0.conf"; }

lab reset

block cable
sudo ip -n wire link set hq-laptop down
on laptop 'ping -c 2 -W 1 192.168.10.1'
on laptop 'ip -br link show eth0'
on laptop 'sudo ethtool eth0 | grep "Link detected"'
sudo ip -n wire link set hq-laptop up
sleep 1
on laptop 'ip -br link show eth0; sudo ethtool eth0 | grep "Link detected"'

block gateway
quiet laptop 'ip route replace default via 192.168.10.99'
on laptop 'curl -sS -m 5 http://192.0.2.21/'
on laptop 'ip route'
on laptop 'ping -c 2 -W 1 192.168.10.99'
on laptop 'ip neigh show 192.168.10.99'
on laptop 'ping -c 1 192.168.10.10'
quiet laptop 'ip route replace default via 192.168.10.1'
on laptop 'ping -c 1 192.0.2.21'

block dns
quiet laptop 'echo nameserver 192.0.2.54 > /etc/resolv.conf'
on laptop 'curl -sS -m 10 http://www.example.com/'
on laptop 'ping -c 1 192.0.2.53'
on laptop 'dig +time=2 +tries=1 www.example.com | grep -E "timed out|status"'
on laptop 'dig @192.0.2.53 +short www.example.com'
on laptop 'cat /etc/resolv.conf'
quiet laptop 'echo nameserver 192.0.2.53 > /etc/resolv.conf'

block service
lab kill web1 'nginx' TERM
sleep 1
on laptop 'curl -sS http://192.0.2.21/'
on laptop 'ping -c 1 192.0.2.21'
on web1 'ss -tln'
quiet web1 'nginx -c /lab/web1/www/nginx.conf'
on web1 'ss -tln'
on laptop 'curl -sS -o /dev/null -w "%{http_code}\n" http://192.0.2.21/reports/'

block case
HQ=$(key hq); BR=$(key branch)
wgconf hq <<C
[Interface]
Address = 10.20.0.1/24
ListenPort = 51820
PrivateKey = PRIV

[Peer]
PublicKey = $BR
Endpoint = 198.51.100.2:51820
AllowedIPs = 10.20.0.2/32, 192.168.20.0/24
C
wgconf branch <<C
[Interface]
Address = 10.20.0.2/24
ListenPort = 51820
PrivateKey = PRIV

[Peer]
PublicKey = $HQ
Endpoint = 203.0.113.2:51820
AllowedIPs = 10.20.0.0/24, 192.168.10.0/24
C
quiet hq 'wg-quick up wg0'
quiet branch 'wg-quick up wg0'
quiet hq 'nft add table ip hardening; nft add chain ip hardening out "{ type filter hook output priority 0; }"; nft add rule ip hardening out icmp type destination-unreachable drop'
on till 'curl -sS -m 5 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/'
on till 'curl -sS -m 8 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin'
bg hq 'sudo tcpdump -n -t -i eth0 -c 9 tcp port 80 and host 192.168.20.30'
lab exec till ana 'curl -s -m 5 -o /dev/null http://192.168.10.10/big.bin' >/dev/null 2>&1
fg
on files 'ping -c 1 -M do -s 1392 192.168.20.30 | tail -n 2'
on files 'ping -c 1 -W 2 -M do -s 1400 192.168.20.30 | tail -n 2'
on hq 'ip link show wg0 | head -n 1'
on hq 'sudo nft list ruleset | grep -B 3 destination-unreachable'
on hq 'sudo nft add table ip clamp && sudo nft add chain ip clamp syn "{ type filter hook forward priority mangle; }"'
on hq 'sudo nft add rule ip clamp syn oifname wg0 tcp flags syn tcp option maxseg size set 1380 && sudo nft add rule ip clamp syn iifname wg0 tcp flags syn tcp option maxseg size set 1380'
bg hq 'sudo tcpdump -n -t -i eth0 -c 2 "tcp[tcpflags] & tcp-syn != 0"'
on till 'curl -sS -m 30 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin'
fg
