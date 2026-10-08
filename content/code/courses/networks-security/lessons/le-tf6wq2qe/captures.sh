#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo ln -sf "$(realpath ../../lab.sh)" /var/tmp/nslab.sh   # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@sensor is the administrator on the intrusion detection sensor, plugged
# into the DMZ with no address.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; the rule file on sensor written before it is shown with cat;
# a pause after each start and each reload for Suricata's engine to come up;
# a login endpoint that answers every POST, which is what the application of
# the lab does. The load in the threshold block is fifteen requests from one
# machine, a few seconds apart from nothing, and nothing in the lesson
# guesses a password: the requests carry none.
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

block rules
quiet sensor 'cat > /etc/suricata/rules/local.rules <<"R"
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"login form posted from outside"; flow:to_server,established; http.method; content:"POST"; http.uri; content:"/login"; startswith; detection_filter:track by_src, count 10, seconds 60; classtype:attempted-user; sid:1000201; rev:1;)
R'
root sensor 'cat /etc/suricata/rules/local.rules'
quiet sensor 'sed -i "/^rule-files:/,/^[a-z]/{s#^  - local.rules#  - local.rules\n  - http-events.rules#}" /etc/suricata/suricata.yaml'
root sensor 'grep -A2 "^rule-files" /etc/suricata/suricata.yaml; ls /etc/suricata/rules/http-events.rules'
root sensor 'suricata -T -c /etc/suricata/suricata.yaml 2>&1 | tail -1'
root sensor 'suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid'
sleep 10

block threshold
on remote 'for i in $(seq 15); do curl -s -o /dev/null -w "%{http_code} " -d "user=ana" http://www.example.com/login; done; echo'
sleep 2
root sensor 'grep -c 1000201 /var/log/suricata/fast.log'
root sensor 'jq -c "select(.event_type==\"alert\" and .alert.signature_id==1000201) | [.timestamp[11:19], .src_ip, .http.url]" /var/log/suricata/eve.json | head -2'

block anomaly
on remote 'printf "GET / HTTP/1.1\r\n\r\n" | nc -w2 www.example.com 80 | head -1'
sleep 2
root sensor 'jq -c "select(.event_type==\"alert\" and .alert.signature_id!=1000201) | [.alert.signature_id, .alert.signature, .src_ip]" /var/log/suricata/eve.json'

block baseline
on remote 'for n in www shop mail vpn ftp dev test admin intranet portal; do dig +short @192.0.2.53 $n.example.com >/dev/null; done'
on laptop 'dig +short @192.0.2.53 www.example.com >/dev/null'
sleep 2
root sensor 'jq -r "select(.event_type==\"dns\" and .dns.type==\"query\") | .src_ip" /var/log/suricata/eve.json | sort | uniq -c | sort -rn'
root sensor 'jq -r "select(.event_type==\"dns\" and .dns.type==\"query\" and .src_ip==\"203.0.113.50\") | .dns.rrname" /var/log/suricata/eve.json | tr "\n" " "; echo'

block tuning
quiet sensor 'printf "suppress gen_id 1, sig_id 1000201, track by_src, ip 203.0.113.70\n" > /etc/suricata/threshold.config'
root sensor 'cat /etc/suricata/threshold.config'
root sensor 'kill -USR2 $(cat /var/log/suricata/suricata.pid); sleep 6; grep -c "rule reload complete" /var/log/suricata/suricata.log'
on branch 'for i in $(seq 15); do curl -s -o /dev/null -d "user=ana" http://www.example.com/login; done'
sleep 2
root sensor 'jq -r "select(.event_type==\"alert\" and .alert.signature_id==1000201) | .src_ip" /var/log/suricata/eve.json | sort | uniq -c'
