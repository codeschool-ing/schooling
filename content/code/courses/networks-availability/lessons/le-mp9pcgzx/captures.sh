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
# EACH FAULT IS STAGED, AND THAT IS THE POINT OF THE LESSON: something is
# broken on purpose and the transcripts are the search for it. What is
# HOW EACH FAULT IS STAGED, and where the lesson gives it: each section's
# prose says, before its transcript, the command that stages the fault and
# the one that puts it back, and they are the commands run below, word for
# word: the cable (hq-laptop set down and up, on the computer itself), the
# gateway, the resolver, nginx on web1 (netlab.sh kill, then started again).
# The worked case starts from lesson 4's WireGuard between hq and branch: the
# key pairs by lesson 4's own commands and its first two wg0.conf files,
# EXTRACTED with this run's keys put in. The fault, the rule on hq that drops
# the ICMP messages it would send back, is black-hole's sh fence, EXTRACTED
# with `lab.sh fence`; the fix is typed and shown.
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
L4="$HERE/../le-xd1520kt"
prose() { local h=$1; shift; lab exec "$h" ana "$*" >/dev/null 2>&1 || true; }
vm() { ( cd ~ && bash -c "$*" ) >/dev/null 2>&1 || true; }
pub() { lab exec "$1" root "cat /etc/wireguard/$1.pub"; }
OLD_HQ='B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I='
OLD_BR='n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8='
OLD_RM='FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE='
wgfile() {  # wgfile HOST N: lesson 4's Nth wg0.conf, with this run's keys
  bash "$LAB_SH" example "$L4/keys-and-config.md" wg0.conf "$2" |
    sed "s|$OLD_HQ|$HQ|; s|$OLD_BR|$BR|; s|$OLD_RM|${RM:-$OLD_RM}|" |
    lab exec "$1" root "umask 077; sed \"s|^PrivateKey = .*|PrivateKey = \$(cat /etc/wireguard/$1.key)|\" > /etc/wireguard/wg0.conf"
}

lab reset

block cable
vm 'sudo ip -n wire link set hq-laptop down'
on laptop 'ping -c 2 -W 1 192.168.10.1'
on laptop 'ip -br link show eth0'
on laptop 'sudo ethtool eth0 | grep "Link detected"'
vm 'sudo ip -n wire link set hq-laptop up'
sleep 1
on laptop 'ip -br link show eth0; sudo ethtool eth0 | grep "Link detected"'

block gateway
prose laptop 'sudo ip route replace default via 192.168.10.99'
on laptop 'curl -sS -m 5 http://192.0.2.21/'
on laptop 'ip route'
on laptop 'ping -c 2 -W 1 192.168.10.99'
on laptop 'ip neigh show 192.168.10.99'
on laptop 'ping -c 1 192.168.10.10'
prose laptop 'sudo ip route replace default via 192.168.10.1'
on laptop 'ping -c 1 192.0.2.21'

block dns
prose laptop 'echo nameserver 192.0.2.54 | sudo tee /etc/resolv.conf'
on laptop 'curl -sS -m 10 http://www.example.com/'
on laptop 'ping -c 1 192.0.2.53'
on laptop 'dig +time=2 +tries=1 www.example.com | grep -E "timed out|status"'
on laptop 'dig @192.0.2.53 +short www.example.com'
on laptop 'cat /etc/resolv.conf'
prose laptop 'echo nameserver 192.0.2.53 | sudo tee /etc/resolv.conf'

block service
vm 'sudo bash netlab.sh kill web1 nginx'
sleep 1
on laptop 'curl -sS http://192.0.2.21/'
on laptop 'ping -c 1 192.0.2.21'
on web1 'ss -tln'
prose web1 'sudo nginx -c /lab/web1/www/nginx.conf'
on web1 'ss -tln'
on laptop 'curl -sS -o /dev/null -w "%{http_code}\n" http://192.0.2.21/reports/'

block case
for h in hq branch; do
  prose $h "sudo sh -c \"umask 077; wg genkey > /etc/wireguard/$h.key\""
  prose $h "sudo cat /etc/wireguard/$h.key | wg pubkey | sudo tee /etc/wireguard/$h.pub"
done
HQ=$(pub hq); BR=$(pub branch)
wgfile hq 1; wgfile branch 2
prose hq 'sudo wg-quick up wg0'
prose branch 'sudo wg-quick up wg0'
prose hq "$(bash "$LAB_SH" fence "$HERE/black-hole.md" 1)"
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
