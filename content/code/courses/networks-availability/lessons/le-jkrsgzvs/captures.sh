#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of networks-availability, as a
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
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh: a head
# office (hq), a branch, a home behind its own NAT, an ISP and a small data
# centre, as network namespaces on one Linux computer.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the WireGuard keys and the wg0.conf of hq,
# branch and remote, written as root, exactly as lesson 4 built them (the
# lesson shows remote's with cat); wg-quick run as root on hq and branch; and
# between blocks, remote's AllowedIPs line edited as root with wg-quick taken
# down first, which the lesson describes in the prose. The access log read at
# the end is web1's nginx log.
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
key() { lab exec "$1" root "umask 077; wg genkey > /etc/wireguard/key; wg pubkey < /etc/wireguard/key"; }
wgconf() { lab exec "$1" root "umask 077; sed \"s|PRIV|\$(cat /etc/wireguard/key)|\" > /etc/wireguard/wg0.conf"; }
remote_allowed() {  # remote_allowed 'LIST'
  quiet remote 'wg-quick down wg0'
  lab exec remote root "sed -i 's|^AllowedIPs = .*|AllowedIPs = $1|' /etc/wireguard/wg0.conf"
}

lab reset
HQ=$(key hq); BR=$(key branch); RM=$(key remote)
wgconf hq <<C
[Interface]
Address = 10.20.0.1/24
ListenPort = 51820
PrivateKey = PRIV

[Peer]
PublicKey = $BR
Endpoint = 198.51.100.2:51820
AllowedIPs = 10.20.0.2/32, 192.168.20.0/24

[Peer]
PublicKey = $RM
AllowedIPs = 10.20.0.3/32
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
wgconf remote <<C
[Interface]
Address = 10.20.0.3/24
PrivateKey = PRIV

[Peer]
PublicKey = $HQ
Endpoint = vpn.example.com:51820
AllowedIPs = 10.20.0.0/24, 192.168.10.0/24
PersistentKeepalive = 25
C
quiet hq 'wg-quick up wg0'
quiet branch 'wg-quick up wg0'

block site-to-site
on till 'traceroute -n -q 1 192.168.10.10'
on till 'ip route'

block split
quiet remote 'wg-quick up wg0'
on remote 'sudo grep AllowedIPs /etc/wireguard/wg0.conf'
on remote 'ip route get 192.168.10.10; ip route get 192.0.2.21'
on remote 'traceroute -n -q 1 192.0.2.21'
on remote 'curl -s http://192.0.2.21/'

block full
remote_allowed '0.0.0.0/0'
on remote 'sudo wg-quick up wg0'
on remote 'ip route get 192.0.2.21'
on remote 'traceroute -n -q 1 192.0.2.21'
on remote 'curl -s http://192.0.2.21/'
on web1 'tail -n 2 /lab/web1/www/logs/access.log | cut -d" " -f1-7'

block overlap
remote_allowed '10.20.0.0/24, 192.168.10.0/24, 192.168.1.0/24'
on remote 'ip route | grep 192.168.1.0'
on remote 'sudo wg-quick up wg0'
remote_allowed '10.20.0.0/24, 192.168.10.0/24'
quiet remote 'wg-quick up wg0'
