#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of networks-availability, as a
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
# (lesson 1): a head office (hq), a branch, a home behind its own NAT, an ISP
# and a small data centre, as network namespaces on one Linux computer.
#
# WHAT THE STUDENT DOES THAT A TRANSCRIPT DOES NOT SHOW, and where the lesson
# gives it. Every configuration file is EXTRACTED from the lesson's own
# examples with `lab.sh example`, so what the page hands over is what ran:
# hq's swanctl.conf from "IKEv2", branch's as that file with the six values
# the same section's table swaps, and hq's `home` connection and remote's file
# from "NAT traversal". The commands below marked `prose` are given in the
# lesson's text, word for word, rather than in a transcript: starting charon,
# loading a file on the other router, tearing a connection down between runs,
# and the two sed edits and their reversal. They run as ana with sudo, as the
# student types them.
# IPsec here is strongSwan's userspace ESP (kernel-libipsec), which netlab.sh
# switches on; the kernel this was recorded on has no ESP.
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
# branch's file is hq's with the six values the lesson's table swaps.
mirror() {
  sed -e 's/local_addrs = 203.0.113.2/local_addrs = @R/; s/remote_addrs = 198.51.100.2/remote_addrs = 203.0.113.2/; s/@R/198.51.100.2/' \
      -e '/local {/,/}/s/id = hq.example.com/id = @B/; /remote {/,/}/s/id = branch.example.com/id = hq.example.com/; s/@B/branch.example.com/' \
      -e 's|local_ts = 192.168.10.0/24|local_ts = @T|; s|remote_ts = 192.168.20.0/24|remote_ts = 192.168.10.0/24|; s|@T|192.168.20.0/24|'
}
charon() { prose "$1" 'sudo setsid /usr/lib/ipsec/charon >/dev/null 2>&1 &'; }

lab reset
bash "$LAB_SH" example "$HERE/ike.md" swanctl.conf | lab exec hq root 'cat > /etc/swanctl/swanctl.conf'
bash "$LAB_SH" example "$HERE/ike.md" swanctl.conf | mirror | lab exec branch root 'cat > /etc/swanctl/swanctl.conf'
charon hq; charon branch; sleep 1

block config
on hq 'sudo cat /etc/swanctl/swanctl.conf'

block load
prose branch 'sudo swanctl --load-all'
on hq 'sudo swanctl --load-all'
on hq 'sudo swanctl --list-conns'

block trap
bg isp 'sudo tcpdump -n -t -i eth0 -c 4 udp port 500 or udp port 4500'
on laptop 'ping -c 3 192.168.20.30'
fg

block sas
on hq 'sudo swanctl --list-sas'

block esp
bg isp 'sudo tcpdump -n -t -v -i eth0 -c 2 esp'
lab exec laptop ana 'ping -c 1 192.168.20.30' >/dev/null 2>&1
fg

block dark
bg isp 'sudo tcpdump -l -n -t -A -i eth0 -c 10 esp | grep -c -E "GET|served"'
lab exec till ana 'curl -s http://192.168.10.10/' >/dev/null 2>&1
fg
on till 'curl -s http://192.168.10.10/'

block tshark-ike
prose hq 'sudo swanctl --terminate --ike offices'
sleep 1
bg isp 'tshark -n -i eth0 -c 4 -f "udp port 500"'
on laptop 'ping -c 2 192.168.20.30'
fg

block initiate
prose hq 'sudo swanctl --terminate --ike offices'
sleep 1
on hq 'sudo swanctl --initiate --child lans'

block wrong-key
prose hq 'sudo swanctl --terminate --ike offices'
prose branch "sudo sed -i 's/7294-Quill/7294-Quil/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all"
sleep 1
on hq 'sudo swanctl --initiate --child lans'
prose branch "sudo sed -i 's/7294-Quil\"/7294-Quill\"/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all"

block selectors
prose hq 'sudo swanctl --terminate --ike offices'
prose hq "sudo sed -i 's/192.168.20.0/192.168.30.0/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all"
sleep 1
on hq 'sudo swanctl --initiate --child lans 2>&1 | tail -5'
prose hq "sudo sed -i 's/192.168.30.0/192.168.20.0/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all"

block nat
bash "$LAB_SH" example "$HERE/nat-traversal.md" swanctl.conf 1 | lab exec hq root 'cat >> /etc/swanctl/swanctl.conf'
bash "$LAB_SH" example "$HERE/nat-traversal.md" swanctl.conf 2 | lab exec remote root 'cat > /etc/swanctl/swanctl.conf'
charon remote; sleep 1
prose hq 'sudo swanctl --load-all'
prose remote 'sudo swanctl --load-all'
bg isp 'sudo tcpdump -n -t -i eth1 -c 6 udp and host 198.51.100.77'
on remote 'sudo swanctl --initiate --child office | grep -E "NAT|sending|received|virtual|established"'
lab exec remote ana 'ping -c 1 192.168.10.10' >/dev/null 2>&1
fg
on remote 'ping -c 2 192.168.10.10'
on hq 'sudo swanctl --list-sas --ike home'
