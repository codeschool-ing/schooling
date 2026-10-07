#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of networks-availability, as a
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
# itself, built by lab.sh reset; www's address, 192.0.2.80, put on lb1 by
# hand (lesson 16 is where two balancers share it); each backend section
# written into lb1's haproxy.cfg as root (the lesson shows each one with
# grep), and HAProxy restarted as root after every change; and web3's nginx
# stopped as root before the last two requests of the cookie block, and started
# again after them.
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
backend() {  # backend (the backend section on stdin): write it, restart HAProxy
  local body; body=$(cat)
  lab exec lb1 root 'cat > /etc/haproxy/haproxy.cfg' <<C
global
    log stdout format raw local0
    stats socket /run/haproxy.sock mode 600 level admin

defaults
    mode http
    log global
    option httplog
    timeout connect 2s
    timeout client 30s
    timeout server 30s

frontend www
    bind 192.0.2.80:80
    default_backend web

$body
C
  lab kill lb1 'haproxy -db' TERM; sleep 0.5
  quiet lb1 'setsid haproxy -db -f /etc/haproxy/haproxy.cfg </dev/null >>/run/haproxy.log 2>&1 &'
  sleep 1.5
}
show() { on lb1 'sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg'; }

lab reset
quiet lb1 'ip addr add 192.0.2.80/24 dev eth0'

block roundrobin
backend <<'B'
backend web
    balance roundrobin
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
B
show
on laptop 'for i in $(seq 6); do curl -s http://www.example.com/; done'

block weights
backend <<'B'
backend web
    balance roundrobin
    server web1 192.0.2.21:80 weight 2
    server web2 192.0.2.22:80 weight 1
    server web3 192.0.2.23:80 weight 1
B
show
on laptop 'for i in $(seq 8); do curl -s http://www.example.com/; done | sort | uniq -c'

block slow-rr
on laptop 'curl -s -o /dev/null http://www.example.com/slow.txt & sleep 0.3; for i in 1 2 3 4; do curl -s http://www.example.com/; done; wait'

block leastconn
backend <<'B'
backend web
    balance leastconn
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
B
show
on laptop 'curl -s -o /dev/null http://www.example.com/slow.txt & sleep 0.3; for i in 1 2 3 4; do curl -s http://www.example.com/; done; wait'
( lab exec laptop ana 'curl -s -o /dev/null http://www.example.com/slow.txt' >/dev/null 2>&1 & )
sleep 0.5
on lb1 'echo "show stat" | sudo socat stdio /run/haproxy.sock | cut -d, -f1,2,5 | grep -E "^web,web"'
sleep 4

block source
backend <<'B'
backend web
    balance source
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
B
show
on laptop 'for i in $(seq 4); do curl -s http://www.example.com/; done'
on remote 'for i in $(seq 4); do curl -s http://www.example.com/; done'
on till 'for i in $(seq 4); do curl -s http://www.example.com/; done'
on isp 'for i in $(seq 4); do curl -s http://www.example.com/; done'
on ns 'for i in $(seq 4); do curl -s http://www.example.com/; done'

block cookie
backend <<'B'
backend web
    balance roundrobin
    cookie SERVERID insert indirect nocache
    server web1 192.0.2.21:80 cookie w1
    server web2 192.0.2.22:80 cookie w2
    server web3 192.0.2.23:80 cookie w3
B
show
on laptop 'curl -s -D - -o /dev/null http://www.example.com/ | grep -i set-cookie'
on laptop 'for i in $(seq 4); do curl -s -b "SERVERID=w3" http://www.example.com/; done'
on laptop 'for i in $(seq 3); do curl -s http://www.example.com/; done'
lab kill web3 nginx TERM
on laptop 'curl -s -b "SERVERID=w3" http://www.example.com/'
backend <<'B'
backend web
    balance roundrobin
    option redispatch
    cookie SERVERID insert indirect nocache
    server web1 192.0.2.21:80 cookie w1 check inter 1s
    server web2 192.0.2.22:80 cookie w2 check inter 1s
    server web3 192.0.2.23:80 cookie w3 check inter 1s
B
sleep 3
show
on laptop 'curl -s -D - -b "SERVERID=w3" http://www.example.com/ | grep -iE "set-cookie|served"'
quiet web3 'nginx -c /lab/web3/www/nginx.conf'
