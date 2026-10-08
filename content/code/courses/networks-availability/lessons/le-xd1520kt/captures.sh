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
# gives it. The three wg0.conf files are EXTRACTED from "Two keys and a short
# file" with `lab.sh example`; the listings carry the keys of the recording
# the lesson quotes and hide the private key, and the lesson tells the student
# to put their own machine's keys there, which is what wgfile() does with this
# run's keys. The OpenVPN server.conf is extracted the same way, and Ana's
# client.conf is lesson 3's example with the one line the lesson says to add.
# Every command in an sh fence is extracted with `lab.sh fence` and typed as
# ana with sudo; the commands the prose gives inline are the `prose` lines,
# word for word. Two edits the prose describes rather than spells, both of
# them a key typed into a file, are the sed lines marked `edit`.
# WireGuard here is wireguard-go, which wg-quick falls back to by itself: the
# kernel this was recorded on has no WireGuard module.
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
prose() { local h=$1; shift; lab exec "$h" ana "$*" >/dev/null 2>&1 || true; }
fence() { prose "$1" "$(bash "$LAB_SH" fence "$HERE/$2" "$3")"; }
pub() { lab exec "$1" root "cat /etc/wireguard/$1.pub"; }
# The keys the listings carry, from the recording the lesson quotes.
OLD_HQ='B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I='
OLD_BR='n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8='
OLD_RM='FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE='
# wgfile HOST N: the Nth wg0.conf of the lesson, with this run's keys in it.
wgfile() {
  bash "$LAB_SH" example "$HERE/keys-and-config.md" wg0.conf "$2" |
    sed "s|$OLD_HQ|$HQ|; s|$OLD_BR|$BR|; s|$OLD_RM|$RM|" |
    lab exec "$1" root "umask 077; sed \"s|^PrivateKey = .*|PrivateKey = \$(cat /etc/wireguard/$1.key)|\" > /etc/wireguard/wg0.conf"
}

lab reset

block keys
on hq 'sudo sh -c "umask 077; wg genkey > /etc/wireguard/hq.key"'
on hq 'sudo cat /etc/wireguard/hq.key | wg pubkey | sudo tee /etc/wireguard/hq.pub'
on hq 'sudo ls -l /etc/wireguard'
for h in branch remote; do
  prose $h "sudo sh -c \"umask 077; wg genkey > /etc/wireguard/$h.key\""
  prose $h "sudo cat /etc/wireguard/$h.key | wg pubkey | sudo tee /etc/wireguard/$h.pub"
done
HQ=$(pub hq); BR=$(pub branch); RM=$(pub remote)
wgfile hq 1; wgfile branch 2; wgfile remote 3

block config
on hq 'sudo sed "s|^PrivateKey = .*|PrivateKey = (hidden here, in the file it is the key)|" /etc/wireguard/wg0.conf'

block up
on hq 'sudo wg-quick up wg0'
prose branch 'sudo wg-quick up wg0'
bg isp 'tshark -n -i eth1 -c 4 -f "udp port 51820"'
on laptop 'ping -c 2 192.168.20.30'
fg
on hq 'sudo wg show'

block routes
on hq 'ip route | grep wg0'

block allowed
prose branch "sudo wg set wg0 peer $HQ allowed-ips 10.20.0.1/32"
on branch 'sudo wg show wg0 allowed-ips'
on laptop 'ping -c 2 -W 1 192.168.20.30'
on branch "sudo wg set wg0 peer $HQ allowed-ips 10.20.0.1/32,192.168.10.0/24"
on laptop 'ping -c 1 192.168.20.30'

block roaming
prose remote 'sudo wg-quick up wg0'
sleep 2
on remote 'ping -c 1 192.168.10.10'
on hq "sudo wg show wg0 endpoints"

block wrong-key
prose remote 'sudo wg-quick down wg0'
prose hq 'sudo wg-quick down wg0 && sudo wg-quick up wg0'
lab exec remote root "sed -i 's|^PublicKey = .*|PublicKey = $BR|' /etc/wireguard/wg0.conf"   # edit
prose remote 'sudo wg-quick up wg0'
bg isp 'sudo tcpdump -n -ttt -i eth1 -c 2 udp port 51820 and host 198.51.100.77'
on remote 'ping -c 7 -W 1 192.168.10.10'
fg
on remote 'sudo wg show wg0 latest-handshakes'
prose remote 'sudo wg-quick down wg0'
lab exec remote root "sed -i 's|^PublicKey = .*|PublicKey = $HQ|' /etc/wireguard/wg0.conf"   # edit

block openvpn
prose hq 'sudo wg-quick down wg0'
bash "$LAB_SH" example "$HERE/openvpn.md" server.conf | lab exec hq root 'cat > /etc/openvpn/server.conf'
bash "$LAB_SH" example "$HERE/../le-swm42nrg/tls-vpn.md" client.conf |
  sed '/^key vpn-ana.key$/a tls-crypt tc.key' | lab exec remote root 'cat > /etc/openvpn/client.conf'
fence hq openvpn.md 1
fence remote openvpn.md 2
on hq 'cat /etc/openvpn/server.conf'
on hq 'sudo head -3 /etc/openvpn/tc.key'
fence hq openvpn.md 3
sleep 1
bg isp 'tshark -n -i eth1 -c 6 -f "udp port 1194"'
fence remote openvpn.md 4
sleep 4
fg
on remote 'ping -c 1 192.168.10.10'
sleep 7
on hq 'sudo cat /run/openvpn-status.log'
on hq 'sudo grep -E "Peer Connection|primary virtual" /run/openvpn.log'
