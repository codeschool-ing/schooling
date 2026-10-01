#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of networks-availability, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
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
# itself, built by lab.sh reset; net.ipv4.ip_nonlocal_bind set on lb1 and
# lb2, so the standby's HAProxy can listen on an address it does not hold
# yet; the haproxy.cfg and keepalived.conf of both balancers, written below
# as root (the lesson shows lb1's with cat); HAProxy and keepalived started
# as root on both, logging to /run/haproxy.log and /run/keepalived.log; and
# each failure, which is a process killed by pid as root with lab.sh kill.
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
  ( timeout -s INT 40 sudo bash "$LAB_SH" exec "$h" ana "$*" >> "$BG/out" 2>&1 || true ) &
  echo $! > "$BG/pid"
  sleep "${BG_WAIT:-1.5}"
}
fg() { wait "$(cat "$BG/pid")" 2>/dev/null || true; cat "$BG/out"; }
block() { printf '##### %s\n' "$1"; }
hap_conf() {  # hap_conf HOST
  lab exec "$1" root 'cat > /etc/haproxy/haproxy.cfg' <<'C'
global
    log stdout format raw local0
    stats socket /run/haproxy.sock mode 600 level admin

defaults
    mode http
    log global
    option httplog
    timeout connect 2s
    timeout client 10s
    timeout server 10s

frontend www
    bind 192.0.2.80:80
    bind 192.0.2.81:80
    default_backend web

frontend health
    bind 127.0.0.1:8404
    monitor-uri /health

backend web
    balance roundrobin
    option httpchk GET /
    server web1 192.0.2.21:80 check inter 1s fall 2 rise 2
    server web2 192.0.2.22:80 check inter 1s fall 2 rise 2
    server web3 192.0.2.23:80 check inter 1s fall 2 rise 2
C
}
ka_conf() {  # ka_conf HOST PRIO_FOR_80 PRIO_FOR_81
  lab exec "$1" root 'cat > /etc/keepalived/keepalived.conf' <<C
global_defs {
    enable_script_security
    script_user root
}
vrrp_script haproxy_alive {
    script "/usr/bin/curl -sf -o /dev/null http://127.0.0.1:8404/health"
    interval 1
    fall 2
    rise 2
}
vrrp_instance www_a {
    state BACKUP
    interface eth0
    virtual_router_id 80
    priority $2
    advert_int 1
    virtual_ipaddress {
        192.0.2.80/24
    }
    track_script {
        haproxy_alive
    }
}
C
  [ -n "${3:-}" ] && lab exec "$1" root 'cat >> /etc/keepalived/keepalived.conf' <<C
vrrp_instance www_b {
    state BACKUP
    interface eth0
    virtual_router_id 81
    priority $3
    advert_int 1
    virtual_ipaddress {
        192.0.2.81/24
    }
    track_script {
        haproxy_alive
    }
}
C
  return 0
}
hap_start() { quiet "$1" 'setsid haproxy -db -f /etc/haproxy/haproxy.cfg </dev/null >>/run/haproxy.log 2>&1 &'; }
ka_start() { quiet "$1" 'setsid keepalived -n -l -f /etc/keepalived/keepalived.conf -p /run/keepalived.pid -r /run/vrrp.pid </dev/null >>/run/keepalived.log 2>&1 &'; }
who() { on laptop 'for i in 1 2 3 4 5 6; do curl -s http://www.example.com/; done'; }

lab reset
for h in lb1 lb2; do quiet "$h" 'sysctl -qw net.ipv4.ip_nonlocal_bind=1'; hap_conf "$h"; done
ka_conf lb1 150
ka_conf lb2 100

block configs
on lb1 'cat /etc/haproxy/haproxy.cfg'
on lb1 'cat /etc/keepalived/keepalived.conf'

block active-passive
for h in lb1 lb2; do hap_start "$h"; done
ka_start lb2; sleep 1; ka_start lb1; sleep 6
on lb1 'ip -br addr show eth0'
on lb2 'ip -br addr show eth0'
on laptop 'dig +short www.example.com'
who
on lb1 'tail -n 3 /run/haproxy.log'
on lb2 'tail -n 3 /run/haproxy.log'

block lb-fails
BG_WAIT=0.5 bg laptop 'for i in $(seq 1 30); do printf "%s " $(date +%T.%N | cut -c1-12); curl -s -m 1 http://www.example.com/ || echo "(no answer)"; sleep 0.2; done'
sleep 2
lab kill lb1 'haproxy -db' KILL
fg
on lb1 'grep -E "haproxy_alive|Entering" /run/keepalived.log | tail -n 3'
on lb2 'ip -br addr show eth0'

block health
hap_start lb1; sleep 4
lab kill web2 'nginx' TERM
sleep 3
on lb2 'grep -E "web2" /run/haproxy.log | tail -n 2'
on lb2 'echo "show stat" | sudo socat stdio /run/haproxy.sock | cut -d, -f1,2,18 | grep -E "^web,"'
who
quiet web2 'nginx -c /lab/web2/www/nginx.conf'
sleep 3
on lb2 'grep -E "web2" /run/haproxy.log | tail -n 1'

block active-active
for h in lb1 lb2; do lab kill "$h" 'keepalived' TERM; done; sleep 1
for h in lb1 lb2; do quiet "$h" 'ip addr del 192.0.2.80/24 dev eth0; ip addr del 192.0.2.81/24 dev eth0'; done
ka_conf lb1 150 100
ka_conf lb2 100 150
ka_start lb1; ka_start lb2; sleep 6
on lb1 'ip -br addr show eth0'
on lb2 'ip -br addr show eth0'
on laptop 'curl -s http://192.0.2.80/; curl -s http://192.0.2.81/'
on lb1 'tail -n 1 /run/haproxy.log'
on lb2 'tail -n 1 /run/haproxy.log'
lab kill lb2 'haproxy -db' KILL
sleep 5
on lb1 'ip -br addr show eth0'
