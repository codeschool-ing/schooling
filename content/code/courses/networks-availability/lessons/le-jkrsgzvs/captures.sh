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
# WHAT THE STUDENT DOES THAT A TRANSCRIPT DOES NOT SHOW, and where the lesson
# gives it. The starting point is lesson 4's first section, which this
# lesson's first section names: the key pairs made by lesson 4's own commands,
# the three wg0.conf files EXTRACTED from lesson 4's examples with this run's
# keys put in, and the tunnel brought up on hq and branch. Every command in an
# sh fence is extracted with `lab.sh fence` and typed as ana with sudo; the
# commands the prose gives inline are the `prose` lines, word for word. The
# access log read at the end is web1's nginx log, where netlab.sh keeps it.
# WireGuard here is wireguard-go, which wg-quick falls back to by itself.
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
fence() { prose "$1" "$(bash "$LAB_SH" fence "$HERE/$2" "$3")"; }
pub() { lab exec "$1" root "cat /etc/wireguard/$1.pub"; }
OLD_HQ='B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I='
OLD_BR='n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8='
OLD_RM='FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE='
wgfile() {  # wgfile HOST N: lesson 4's Nth wg0.conf, with this run's keys
  bash "$LAB_SH" example "$L4/keys-and-config.md" wg0.conf "$2" |
    sed "s|$OLD_HQ|$HQ|; s|$OLD_BR|$BR|; s|$OLD_RM|$RM|" |
    lab exec "$1" root "umask 077; sed \"s|^PrivateKey = .*|PrivateKey = \$(cat /etc/wireguard/$1.key)|\" > /etc/wireguard/wg0.conf"
}

lab reset
for h in hq branch remote; do
  prose $h "sudo sh -c \"umask 077; wg genkey > /etc/wireguard/$h.key\""
  prose $h "sudo cat /etc/wireguard/$h.key | wg pubkey | sudo tee /etc/wireguard/$h.pub"
done
HQ=$(pub hq); BR=$(pub branch); RM=$(pub remote)
wgfile hq 1; wgfile branch 2; wgfile remote 3
prose hq 'sudo wg-quick up wg0'
prose branch 'sudo wg-quick up wg0'

block site-to-site
on till 'traceroute -n -q 1 192.168.10.10'
on till 'ip route'

block split
prose remote 'sudo wg-quick up wg0'
on remote 'sudo grep AllowedIPs /etc/wireguard/wg0.conf'
on remote 'ip route get 192.168.10.10; ip route get 192.0.2.21'
on remote 'traceroute -n -q 1 192.0.2.21'
on remote 'curl -s http://192.0.2.21/'

block full
fence remote split-and-full.md 1
on remote 'sudo wg-quick up wg0'
on remote 'ip route get 192.0.2.21'
on remote 'traceroute -n -q 1 192.0.2.21'
on remote 'curl -s http://192.0.2.21/'
on web1 'tail -n 2 /lab/web1/www/logs/access.log | cut -d" " -f1-7'

block overlap
fence remote dns-and-overlap.md 1
on remote 'ip route | grep 192.168.1.0'
on remote 'sudo wg-quick up wg0'
prose remote "sudo sed -i 's|^AllowedIPs = .*|AllowedIPs = 10.20.0.0/24, 192.168.10.0/24|' /etc/wireguard/wg0.conf"
prose remote 'sudo wg-quick up wg0'
