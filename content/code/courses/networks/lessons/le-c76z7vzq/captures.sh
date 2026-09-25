#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of networks, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds an office, an
# ISP and a small internet out of network namespaces on one Linux computer,
# with its own DNS root and its own certificate authority. Nothing reaches the
# real internet, which is why the addresses and names are the ones reserved
# for documentation. A line that starts with ana@laptop ran on the machine
# called laptop, and so on.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset; a 200 kB text file written into the
# web server's folder; in the states block, an nc connection to port 22 left
# open on laptop and then killed; in the loss-after block, a rule on router
# that drops one in five of the packets www sends from port 443, removed
# straight after; and in the drop-wire and rst-wire blocks, the same nc
# attempts run again with no output of their own, so tcpdump has something
# to print.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.

set -uo pipefail
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
block() { printf '##### %s\n' "$1"; }

later() {
  printf 'ana@%s:~$ %s\n' "$2" "$3" > "/tmp/later.$1"
  lab exec "$2" ana "$3" >> "/tmp/later.$1" 2>&1 &
  eval "LATER_$1=$!"
  sleep 1.5
}
collect() { eval "wait \$LATER_$1"; cat "/tmp/later.$1"; rm -f "/tmp/later.$1"; }

lab reset
quiet www 'for i in $(seq 1 2000); do echo "line $i of the price list, padded to a hundred characters so the file is large enough ....."; done > /var/www/example/prices.txt'

block listening
on resolver 'sudo ss -tulpn'
on www 'sudo ss -tlpn'
on laptop "grep -wE '^(ssh|domain|http|https|smtp|imaps)' /etc/services"

block handshake
later hs www 'sudo tcpdump -n -i eth0 -c 10 tcp port 80'
lab exec laptop ana 'curl -s -o /dev/null http://www.example.com/' >/dev/null 2>&1
collect hs

block states
lab exec laptop ana 'sleep 60 | nc 192.0.2.80 22 >/dev/null 2>&1 &' >/dev/null 2>&1
sleep 1
on laptop 'ss -tn'
on www 'ss -tn'
quiet laptop 'pkill -f "nc 192.0.2.80 22"'
sleep 0.5
on laptop 'ss -tan state time-wait'

block loss-before
on www 'nstat -az TcpRetransSegs'
on laptop "curl -sS -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://www.example.com/prices.txt"
on www 'nstat -az TcpRetransSegs'

block loss-after
# The office router now loses one packet in five of what the web server sends.
quiet router 'nft add table inet lossy; nft add chain inet lossy forward "{ type filter hook forward priority 0; }"; nft add rule inet lossy forward tcp sport 443 numgen random mod 100 lt 20 drop'
on laptop "curl -sS -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://www.example.com/prices.txt"
on www 'nstat -az TcpRetransSegs'
quiet router 'nft delete table inet lossy'

block udp-dns
later dns resolver 'sudo tcpdump -n -i eth0 -c 2 udp port 53 and host 203.0.113.2'
lab exec laptop ana 'dig +short www.example.com' >/dev/null 2>&1
collect dns

block udp-open
on laptop 'nc -zuv -w 1 198.51.100.53 53'

block udp-closed
later uc www 'sudo tcpdump -n -i eth0 -c 2 udp port 9999 or icmp'
on laptop 'nc -zuv -w 1 192.0.2.80 9999; echo "exit status $?"'
block udp-closed-wire
collect uc

block firewall
on www 'sudo nft add table inet fw'
on www "sudo nft add chain inet fw input '{ type filter hook input priority 0; }'"
on www 'sudo nft add rule inet fw input tcp dport 3306 drop'
on www 'sudo nft add rule inet fw input tcp dport 5432 reject with tcp reset'
on www 'sudo nft add rule inet fw input udp dport 9998 drop'

block three-answers
on laptop 'nc -zv -w 3 192.0.2.80 8080'
on laptop 'nc -zv -w 3 192.0.2.80 5432'
on laptop 'time nc -zv -w 3 192.0.2.80 3306'

block udp-dropped
on laptop 'nc -zuv -w 1 192.0.2.80 9998; echo "exit status $?"'

block drop-wire
later dw laptop 'sudo tcpdump -n -i eth0 -c 3 tcp port 3306'
lab exec laptop ana 'nc -z -w 5 192.0.2.80 3306' >/dev/null 2>&1
collect dw

block rst-wire
later rw laptop 'sudo tcpdump -n -i eth0 -c 2 tcp port 8080'
lab exec laptop ana 'nc -z -w 3 192.0.2.80 8080' >/dev/null 2>&1
collect rw

lab down
