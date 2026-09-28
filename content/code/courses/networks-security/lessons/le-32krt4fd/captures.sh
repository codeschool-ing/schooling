#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/nslab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@branch is the administrator on the branch office's router, on the
# internet segment; branchpc is a computer in the branch office.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; seal.py written to ana's home on laptop, shown whole in the
# lesson as an annotated example; a recording on fw's internet interface with
# tcpdump in the background, read afterwards; the two WireGuard configuration
# files written between blocks, each shown with cat before it is used. The
# tunnel runs on wireguard-go, WireGuard's implementation in user space,
# because the kernel the course was recorded on has no WireGuard module; it
# speaks the same protocol and is configured with the same wg tool.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/nslab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset
quiet fw 'nft -f baseline.nft'

block symmetric
on laptop 'printf "Payroll for September: 42 people, BRL 318,450.00\n" > payroll.txt; wc -c payroll.txt'
on laptop 'openssl rand -hex 32 > key.hex; wc -c key.hex'
on laptop 'openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -in payroll.txt -out payroll.enc -pass file:key.hex; wc -c payroll.enc; head -c 8 payroll.enc; echo'
on laptop 'openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in payroll.enc -pass file:key.hex'

block aead
quiet laptop 'cat > /home/ana/seal.py <<"PY"
import sys
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

key = AESGCM.generate_key(bit_length=256)
nonce = b"\x00" * 11 + b"\x01"
box = AESGCM(key)

sealed = box.encrypt(nonce, b"pay 318,450.00 to account 4471", None)
print(len(sealed), "bytes sealed")
print(box.decrypt(nonce, sealed, None).decode())

tampered = bytearray(sealed)
tampered[4] ^= 0x01
try:
    box.decrypt(nonce, bytes(tampered), None)
except Exception as e:
    print("refused:", type(e).__name__)
PY
chown ana:ana /home/ana/seal.py'
on laptop 'python3 seal.py'

block keypairs
on laptop 'openssl genpkey -algorithm X25519 -out ana.key; openssl pkey -in ana.key -pubout -out ana.pub; cat ana.pub'
on app 'openssl genpkey -algorithm X25519 -out app.key; openssl pkey -in app.key -pubout -out app.pub; cat app.pub'
quiet laptop 'true'
cp /lab/app/home/ana/app.pub /lab/laptop/home/ana/app.pub; cp /lab/laptop/home/ana/ana.pub /lab/app/home/ana/ana.pub; chown ana:ana /lab/laptop/home/ana/app.pub /lab/app/home/ana/ana.pub
on laptop 'openssl pkeyutl -derive -inkey ana.key -peerkey app.pub | sha256sum'
on app 'openssl pkeyutl -derive -inkey app.key -peerkey ana.pub | sha256sum'

block speed
on laptop 'openssl speed -seconds 1 -bytes 16384 -evp aes-256-gcm 2>/dev/null | tail -2'
on laptop 'openssl speed -seconds 1 rsa2048 2>/dev/null | tail -2'
on laptop 'openssl speed -seconds 1 ecdhx25519 2>/dev/null | tail -2'

block wg-keys
root fw 'umask 077; wg genkey > wg.key; wg pubkey < wg.key > wg.pub; cat wg.pub'
root branch 'umask 077; wg genkey > wg.key; wg pubkey < wg.key > wg.pub; cat wg.pub'
FWPUB=$(cat /lab/fw/root/wg.pub); BRPUB=$(cat /lab/branch/root/wg.pub)
quiet fw "printf '[Interface]\nListenPort = 51820\nPrivateKey = %s\n\n[Peer]\n# the branch office\nPublicKey = %s\nEndpoint = 203.0.113.70:51820\nAllowedIPs = 10.99.0.2/32, 192.168.30.0/24\n' \"\$(cat wg.key)\" '$BRPUB' > /root/wg0.conf"
quiet branch "printf '[Interface]\nListenPort = 51820\nPrivateKey = %s\n\n[Peer]\n# head office\nPublicKey = %s\nEndpoint = 203.0.113.2:51820\nAllowedIPs = 10.99.0.1/32, 192.168.10.0/24, 192.168.20.0/24\nPersistentKeepalive = 25\n' \"\$(cat wg.key)\" '$FWPUB' > /root/wg0.conf"

block wg-conf
root fw 'sed "s/^PrivateKey = .*/PrivateKey = (the contents of wg.key)/" wg0.conf'
root fw 'wireguard-go wg0 2>/dev/null && wg setconf wg0 wg0.conf && ip addr add 10.99.0.1/24 dev wg0 && ip link set wg0 up && ip route add 192.168.30.0/24 dev wg0'
root branch 'wireguard-go wg0 2>/dev/null && wg setconf wg0 wg0.conf && ip addr add 10.99.0.2/24 dev wg0 && ip link set wg0 up && ip route add 192.168.10.0/24 dev wg0 && ip route add 192.168.20.0/24 dev wg0'
quiet fw 'nft insert rule ip filter input index 0 iifname "eth0" udp dport 51820 accept comment \"the branch tunnel\"; nft insert rule ip filter forward index 0 iifname "wg0" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment \"the branch uses the application\"'
root fw 'nft list ruleset | grep -E "branch"'

block wg-use
quiet fw 'setsid timeout 8 tcpdump -n -i eth0 -c 6 "host 203.0.113.70" > /root/wire.txt 2>/dev/null </dev/null &'
sleep 2
on branchpc 'curl -s -m5 http://192.168.20.10:8080/health'
sleep 2
root fw 'wg show wg0 | sed "s/^  endpoint/  endpoint/" | grep -vE "public key|private key"'
root fw 'cut -d" " -f2- wire.txt'
