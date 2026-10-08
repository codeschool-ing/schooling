#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of networks-security, as a script that produces them.
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
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset: remote runs an SSH server on port 443,
# and www serves HTTPS with a certificate from the lab's own authority, which
# every machine trusts; the ssh client on laptop told to accept remote's host
# key without asking, since the lesson is about the firewall and not about SSH;
# a pause of a few seconds after Suricata starts, for its engine to come up.
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
quiet laptop 'mkdir -p /home/ana/.ssh; printf "Host *\n  StrictHostKeyChecking accept-new\n  UserKnownHostsFile /dev/null\n  LogLevel ERROR\n" > /home/ana/.ssh/config; chown -R ana:ana /home/ana/.ssh'

block portrules
quiet fw 'cat > /root/edge.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" tcp dport { 80, 443 } ct state new accept comment "staff may browse"
    iifname "eth2" udp dport 53 ip daddr 192.0.2.53 ct state new accept
    iifname "eth1" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
  }
}
NFT'
root fw 'cat edge.nft'
root fw 'nft -f edge.nft'
on laptop 'curl -s https://www.example.com/'
on laptop 'nc -w2 203.0.113.50 443 </dev/null'
on laptop 'nc -w2 203.0.113.50 22 </dev/null; echo "exit $?"'

block suricata
root fw 'cat /etc/suricata/rules/local.rules; grep -A1 "^rule-files" /etc/suricata/suricata.yaml'
root fw 'suricata -c /etc/suricata/suricata.yaml --af-packet=eth2 -D --pidfile /var/log/suricata/suricata.pid'
sleep 8
on laptop 'curl -s -o /dev/null https://www.example.com/'
on laptop 'ssh -p 443 -o BatchMode=yes 203.0.113.50 true; echo "exit $?"'
quiet fw 'nft insert rule ip filter forward iifname "eth2" oifname "eth3" tcp dport 8080 ct state new accept'
on laptop 'curl -s -o /dev/null http://192.168.20.10:8080/'
sleep 2
quiet fw 'kill -INT $(cat /var/log/suricata/suricata.pid); while [ -e /var/log/suricata/suricata.pid ]; do sleep 0.2; done'

block flows
root fw 'jq -c "select(.event_type==\"flow\") | [.src_ip, .dest_ip, .dest_port, .app_proto]" /var/log/suricata/eve.json'

block tls-vs-http
root fw 'jq -c "select(.event_type==\"tls\") | .tls | {sni, version, subject, issuerdn}" /var/log/suricata/eve.json'
root fw 'jq -c "select(.event_type==\"http\") | .http | {hostname, url, http_user_agent, status}" /var/log/suricata/eve.json'
root fw 'jq -c "select(.event_type==\"ssh\") | .ssh | {client: .client.software_version, server: .server.software_version}" /var/log/suricata/eve.json'

block apprule
quiet fw 'rm -f /var/log/suricata/*.json /var/log/suricata/*.log'
quiet fw 'cat > /etc/suricata/rules/local.rules <<"R"
alert ssh $HOME_NET any -> $EXTERNAL_NET any (msg:"SSH leaving the LAN"; flow:to_server,established; ssh.proto; content:"2.0"; sid:1000001; rev:1;)
alert tls $HOME_NET any -> any !443 (msg:"TLS on a port other than 443"; flow:to_server,established; tls.sni; content:"."; sid:1000002; rev:1;)
R'
root fw 'cat /etc/suricata/rules/local.rules'
root fw 'suricata -T -c /etc/suricata/suricata.yaml 2>&1 | tail -1'
quiet fw 'suricata -c /etc/suricata/suricata.yaml --af-packet=eth2 -D --pidfile /var/log/suricata/suricata.pid'
sleep 8
on laptop 'ssh -p 443 -o BatchMode=yes 203.0.113.50 true; echo "exit $?"'
on laptop 'curl -s -o /dev/null https://www.example.com/; echo "exit $?"'
sleep 2
root fw 'jq -c "select(.event_type==\"alert\") | [.src_ip, .dest_ip, .dest_port, .alert.signature_id, .alert.signature]" /var/log/suricata/eve.json'
root fw 'cat /var/log/suricata/fast.log'
quiet fw 'kill -INT $(cat /var/log/suricata/suricata.pid)'
