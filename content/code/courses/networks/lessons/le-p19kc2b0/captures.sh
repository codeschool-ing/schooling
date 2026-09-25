#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of networks, as a script that produces them.
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
# the lab itself, built by lab.sh reset, whose nginx on www serves
# example.com over HTTP and HTTPS and hands /app/ to an application on port
# 9000 that is not running; a 200 kB text file and an empty folder, private,
# written into the web server's folder; and in the observer blocks, the
# page fetched again with no output of its own, so tcpdump has something to
# record.
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
quiet www 'for i in $(seq 1 2000); do echo "line $i of the price list, padded to a hundred characters so the file is large enough ....."; done > /var/www/example/prices.txt; mkdir /var/www/example/private'

block by-hand
on laptop "printf 'GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n' | nc -w 3 192.0.2.80 80"

block curl-http
on laptop 'curl -sv -o /dev/null http://www.example.com/prices.txt 2>&1 | grep "^[<>]"'

block follow
on laptop 'curl -sIL http://example.com/ | grep -iE "^HTTP|^location"'

block codes
on laptop 'for p in / /private/ /nothing /app/; do curl -so /dev/null -w "%{http_code} $p\n" https://www.example.com$p; done'
on www 'tail -2 /var/log/nginx/error.log'

block handshake
on laptop "curl -sv -o /dev/null https://www.example.com/ 2>&1 | grep -E '^\* (TLSv1.3|SSL connection|ALPN)'"

block brief
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com -brief </dev/null 2>&1'

block observer-http
later oh router 'sudo timeout 3 tcpdump -n -i eth1 -w /tmp/http.pcap tcp port 80'
lab exec laptop ana 'curl -s -o /dev/null http://www.example.com/prices.txt' >/dev/null 2>&1
collect oh
on router 'tcpdump -n -A -r /tmp/http.pcap 2>/dev/null | grep -E "GET|Host:|Location:"'

block observer-https
later os router 'sudo timeout 3 tcpdump -n -i eth1 -w /tmp/https.pcap tcp port 443'
lab exec laptop ana 'curl -s -o /dev/null https://www.example.com/prices.txt' >/dev/null 2>&1
collect os
on router 'tcpdump -n -A -r /tmp/https.pcap 2>/dev/null | grep -c -E "GET|prices|line 1 of"'
on router 'tcpdump -n -A -r /tmp/https.pcap 2>/dev/null | grep -o -m 1 "www.example.com"'

block versions
on laptop "curl -sv -o /dev/null --http1.1 https://www.example.com/ 2>&1 | grep -E 'ALPN|^> GET|^< HTTP'"
on laptop 'curl -sS -o /dev/null --tls-max 1.1 https://www.example.com/'

block timing
on laptop "curl -so /dev/null -w 'dns        %{time_namelookup}\ntcp        %{time_connect}\ntls        %{time_appconnect}\nfirst byte %{time_starttransfer}\ntotal      %{time_total}\n' https://www.example.com/prices.txt"

lab down
