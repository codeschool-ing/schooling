#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of networks-availability, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved. The keys are generated afresh on every run, so no two runs print
# the same ones.
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
# itself, built by lab.sh reset; branch's and remote's keys and wg0.conf,
# made the same way as hq's (which the lesson shows) and written as root;
# wg-quick run as root on branch and remote; the wrong key given to remote in
# the wrong-key block, and the right one put back; for OpenVPN, the
# certificates from the lab's authority and the two configuration files,
# written as root (the lesson shows them with cat), and the server started as
# root. WireGuard here is wireguard-go, because the kernel this was recorded
# on has no WireGuard module; lab.sh says why.
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
  ( lab exec "$h" ana "$*" >> "$BG/out" 2>&1 || true ) &
  echo $! > "$BG/pid"
  sleep "${BG_WAIT:-1.5}"
}
fg() { wait "$(cat "$BG/pid")" 2>/dev/null || true; cat "$BG/out"; }
block() { printf '##### %s\n' "$1"; }
wgconf() {  # wgconf HOST (body on stdin, with PRIV replaced by HOST's key)
  local body; body=$(cat)
  lab exec "$1" root "umask 077; sed \"s|PRIV|\$(cat /etc/wireguard/$1.key)|\" > /etc/wireguard/wg0.conf" <<< "$body"
}
pub() { lab exec "$1" root "cat /etc/wireguard/$1.pub"; }

lab reset

block keys
on hq 'sudo sh -c "umask 077; wg genkey > /etc/wireguard/hq.key"'
on hq 'sudo cat /etc/wireguard/hq.key | wg pubkey | sudo tee /etc/wireguard/hq.pub'
on hq 'sudo ls -l /etc/wireguard'
quiet branch 'cd /etc/wireguard && umask 077 && wg genkey | tee branch.key | wg pubkey > branch.pub'
quiet remote 'cd /etc/wireguard && umask 077 && wg genkey | tee remote.key | wg pubkey > remote.pub'
HQ=$(pub hq); BR=$(pub branch); RM=$(pub remote)

wgconf hq <<C
[Interface]
Address = 10.20.0.1/24
ListenPort = 51820
PrivateKey = PRIV

# the branch office
[Peer]
PublicKey = $BR
Endpoint = 198.51.100.2:51820
AllowedIPs = 10.20.0.2/32, 192.168.20.0/24

# Ana, at home
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
AllowedIPs = 10.20.0.1/32, 192.168.10.0/24
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

block config
on hq 'sudo sed "s|^PrivateKey = .*|PrivateKey = (hidden here, in the file it is the key)|" /etc/wireguard/wg0.conf'

block up
on hq 'sudo wg-quick up wg0'
quiet branch 'wg-quick up wg0'
bg isp 'tshark -n -i eth1 -c 4 -f "udp port 51820"'
on laptop 'ping -c 2 192.168.20.30'
fg
on hq 'sudo wg show'

block routes
on hq 'ip route | grep wg0'

block allowed
quiet branch "wg set wg0 peer $HQ allowed-ips 10.20.0.1/32"
on branch 'sudo wg show wg0 allowed-ips'
on laptop 'ping -c 2 -W 1 192.168.20.30'
on branch "sudo wg set wg0 peer $HQ allowed-ips 10.20.0.1/32,192.168.10.0/24"
on laptop 'ping -c 1 192.168.20.30'

block roaming
quiet remote 'wg-quick up wg0'
sleep 2
on remote 'ping -c 1 192.168.10.10'
on hq "sudo wg show wg0 endpoints"

block wrong-key
quiet remote 'wg-quick down wg0'
quiet hq 'wg-quick down wg0; wg-quick up wg0'
lab exec remote root "sed -i 's|^PublicKey = .*|PublicKey = $BR|' /etc/wireguard/wg0.conf"
quiet remote 'wg-quick up wg0'
bg isp 'sudo tcpdump -n -ttt -i eth1 -c 2 udp port 51820 and host 198.51.100.77'
on remote 'ping -c 7 -W 1 192.168.10.10'
fg
on remote 'sudo wg show wg0 latest-handshakes'
quiet remote 'wg-quick down wg0'
lab exec remote root "sed -i 's|^PublicKey = .*|PublicKey = $HQ|' /etc/wireguard/wg0.conf"

block openvpn
quiet hq 'wg-quick down wg0'
quiet hq 'cp /lab/tls/ca.crt /lab/tls/vpn-server.crt /lab/tls/vpn-server.key /etc/openvpn/; chmod 600 /etc/openvpn/vpn-server.key; openvpn --genkey tls-crypt /etc/openvpn/tc.key'
quiet remote 'cp /lab/tls/ca.crt /lab/tls/vpn-ana.crt /lab/tls/vpn-ana.key /etc/openvpn/; chmod 600 /etc/openvpn/vpn-ana.key'
lab exec remote root 'cat > /etc/openvpn/tc.key' < <(lab exec hq root 'cat /etc/openvpn/tc.key')
lab exec hq root 'cat > /etc/openvpn/server.conf' <<'C'
dev tun
proto udp
port 1194
server 10.8.0.0 255.255.255.0
topology subnet
ca ca.crt
cert vpn-server.crt
key vpn-server.key
dh none
tls-crypt tc.key
push "route 192.168.10.0 255.255.255.0"
keepalive 10 60
status /run/openvpn-status.log 5
verb 3
C
lab exec remote root 'cat > /etc/openvpn/client.conf' <<'C'
client
dev tun
proto udp
remote vpn.example.com 1194
ca ca.crt
cert vpn-ana.crt
key vpn-ana.key
tls-crypt tc.key
remote-cert-tls server
verify-x509-name vpn.example.com name
verb 3
C
on hq 'cat /etc/openvpn/server.conf'
on hq 'sudo head -3 /etc/openvpn/tc.key'
quiet hq 'cd /etc/openvpn && setsid openvpn --config server.conf </dev/null >/run/openvpn.log 2>&1 &'
sleep 1
bg isp 'tshark -n -i eth1 -c 6 -f "udp port 1194"'
quiet remote 'cd /etc/openvpn && setsid openvpn --config client.conf </dev/null >/run/openvpn.log 2>&1 &'
sleep 4
fg
on remote 'ping -c 1 192.168.10.10'
sleep 7
on hq 'sudo cat /run/openvpn-status.log'
on hq 'sudo grep -E "Peer Connection|primary virtual" /run/openvpn.log'
