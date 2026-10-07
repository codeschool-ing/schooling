#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of networks-security, as a script that produces them.
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
# laptop; root@fw is the administrator on the firewall and root@admin on the
# management machine, which is where the logs are collected.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; the files ulogd.conf and rsyslog.conf on fw, rsyslog.conf,
# host.nft, correlate.py, feed.txt and logrotate.conf on admin, and the one
# Suricata rule on sensor, each shown in the lesson; the daemons started with
# those files. logrotate.conf is checked with logrotate -d and never run: the
# scenario lasts minutes and the file rotates once a day.
# The sensor has no address on any network, so its eve.json is copied into
# admin's collection by the script, where a real sensor would ship it over a
# management interface of its own. The script waits three minutes before reading
# the flow records, because a connection's record is written when the firewall
# forgets it: a closed TCP connection is remembered for two minutes, and the
# kernel notices it has expired up to a minute after that.
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

lab reset >/dev/null 2>&1
quiet fw 'nft -f baseline.nft'

# ---------------------------------------------------------------- the files
quiet fw 'cat > /root/ulogd.conf <<"C"
[global]
logfile="/var/log/lab/ulogd.log"
plugin="/usr/lib/x86_64-linux-gnu/ulogd/ulogd_inpflow_NFCT.so"
plugin="/usr/lib/x86_64-linux-gnu/ulogd/ulogd_inppkt_NFLOG.so"
plugin="/usr/lib/x86_64-linux-gnu/ulogd/ulogd_raw2packet_BASE.so"
plugin="/usr/lib/x86_64-linux-gnu/ulogd/ulogd_filter_IFINDEX.so"
plugin="/usr/lib/x86_64-linux-gnu/ulogd/ulogd_filter_IP2STR.so"
plugin="/usr/lib/x86_64-linux-gnu/ulogd/ulogd_output_JSON.so"
# one record per connection, written when the firewall forgets it
stack=ct1:NFCT,ip2str1:IP2STR,flows:JSON
# one record per packet a log rule sends to group 1
stack=log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str2:IP2STR,drops:JSON

[ct1]
event_mask=0x00000005

[log1]
group=1

[flows]
file="/var/log/lab/flows.json"
sync=1

[drops]
file="/var/log/lab/drops.json"
sync=1
C'
quiet fw 'cat > /root/rsyslog.conf <<"C"
global(workDirectory="/var/log/lab/rsyslog")
module(load="imfile")
input(type="imfile" file="/var/log/lab/drops.json" tag="drops" ruleset="ship" reopenOnTruncate="on")
input(type="imfile" file="/var/log/lab/flows.json" tag="flows" ruleset="ship" reopenOnTruncate="on")
ruleset(name="ship") {
  action(type="omfwd" target="192.168.99.10" port="514" protocol="tcp"
         queue.type="LinkedList" queue.filename="ship" queue.saveOnShutdown="on"
         action.resumeRetryCount="-1")
}
C'
quiet admin 'cat > /root/rsyslog.conf <<"C"
global(workDirectory="/var/log/lab/rsyslog" net.enableDNS="off")
module(load="imtcp")
input(type="imtcp" port="514" address="192.168.99.10" ruleset="remote")
template(name="byhost" type="string" string="/var/log/lab/remote/%hostname%/%programname%.json")
template(name="asis" type="string" string="%msg:2:$%\n")
ruleset(name="remote") {
  action(type="omfile" dynaFile="byhost" template="asis")
}
C'
quiet admin 'cat > /root/host.nft <<"NFT"
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    ip saddr 192.168.99.1 tcp dport 514 accept comment "logs from fw, and nothing else from it"
  }
}
NFT'
quiet sensor 'cat > /etc/suricata/rules/local.rules <<"R"
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"secrets file requested from outside"; flow:to_server,established; http.uri; content:"/.env"; endswith; classtype:attempted-recon; sid:1000231; rev:1;)
R'
quiet admin 'cat > /root/feed.txt <<"F"
# example-intel.org list, 2026-09-28, addresses seen scanning for exposed secrets
203.0.113.50
198.51.100.23
198.51.100.140
F'
quiet admin 'cat > /root/logrotate.conf <<"C"
/var/log/lab/remote/*/*.json {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        kill -HUP $(cat /var/log/lab/rsyslog.pid)
    endscript
}
C
logrotate -d -s /root/logrotate.state /root/logrotate.conf'
lab exec admin root 'cat > /root/correlate.py' <<"PY"
import json, sys
from datetime import datetime

LOGS = "/var/log/lab/remote"
who = sys.argv[1]
events = []


def lines(path):
    with open(path) as f:
        return [json.loads(l) for l in f if l.strip()]


for r in lines(f"{LOGS}/fw/flows.json"):
    if who in (r["src_ip"], r["dest_ip"]):
        t = datetime.fromtimestamp(r["flow.start.sec"]).astimezone()
        size = r["orig.raw.pktlen"] + r["reply.raw.pktlen"]
        events.append((t, "flow ", f'{r["src_ip"]} -> {r["dest_ip"]}:{r["orig.l4.dport"]}  {size} bytes'))

for r in lines(f"{LOGS}/fw/drops.json"):
    if who in (r["src_ip"], r["dest_ip"]):
        t = datetime.fromisoformat(r["timestamp"])
        events.append((t, "drop ", f'{r["src_ip"]} -> {r["dest_ip"]}:{r["dest_port"]}  {r["oob.prefix"]}'))

for r in lines(f"{LOGS}/sensor/eve.json"):
    if r.get("event_type") == "alert" and who in (r["src_ip"], r["dest_ip"]):
        t = datetime.fromisoformat(r["timestamp"])
        events.append((t, "alert", f'{r["src_ip"]} -> {r["dest_ip"]}:{r["dest_port"]}  {r["alert"]["signature"]}'))

for t, kind, what in sorted(events):
    print(t.strftime("%H:%M:%S"), kind, what)
PY

# ------------------------------------------------------------- the lesson
block collect
root fw 'sysctl net.netfilter.nf_conntrack_acct=1 net.netfilter.nf_conntrack_timestamp=1'
root fw "nft 'add rule ip filter forward log group 1 prefix \"forward-drop\"'"
root fw 'ulogd -d -c /root/ulogd.conf'
quiet admin 'mkdir -p /var/log/lab/rsyslog /var/log/lab/remote; nft -f /root/host.nft; rsyslogd -f /root/rsyslog.conf -i /var/log/lab/rsyslog.pid'
quiet fw 'mkdir -p /var/log/lab/rsyslog; rsyslogd -f /root/rsyslog.conf -i /var/log/lab/rsyslog.pid'
quiet sensor 'suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid'
sleep 10

block traffic
on laptop 'curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/'
on laptop 'curl -s -o /dev/null -w "%{http_code}\n" http://app:8080/'
on laptop 'probe db:5432'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/.env'
on remote 'probe 192.0.2.80:22 192.0.2.53:22 192.168.20.30:5432'
sleep 180

block drops
root fw 'wc -l /var/log/lab/drops.json'
root fw 'head -1 /var/log/lab/drops.json | jq .'
root fw "jq -c '[.timestamp, .src_ip, .dest_ip, .dest_port, .\"oob.in\", .\"oob.out\"]' /var/log/lab/drops.json"

block flows
root fw 'wc -l /var/log/lab/flows.json'
root fw "jq -c 'select(.src_ip == \"203.0.113.50\") | {start: .\"flow.start.sec\", end: .\"flow.end.sec\", src: .src_ip, dst: .dest_ip, dport: .\"orig.l4.dport\", sent: .\"orig.raw.pktlen\", received: .\"reply.raw.pktlen\"}' /var/log/lab/flows.json"
root fw "jq -r '[.src_ip, .dest_ip, .\"orig.l4.dport\"] | @tsv' /var/log/lab/flows.json | sort | uniq -c | sort -rn"

block shipped
root admin 'nft list ruleset'
root admin 'ls /var/log/lab/remote/fw/'
root admin 'wc -l /var/log/lab/remote/fw/*.json'
root fw ': > /var/log/lab/drops.json; wc -l /var/log/lab/drops.json'
root admin 'wc -l /var/log/lab/remote/fw/drops.json'
on remote 'probe 192.0.2.80:23'
sleep 2
root admin "tail -1 /var/log/lab/remote/fw/drops.json | jq -c '[.timestamp, .src_ip, .dest_port]'"
root fw 'nc -z -v -w1 admin 22; nc -z -v -w1 admin 514'

block feed
quiet admin 'mkdir -p /var/log/lab/remote/sensor'
lab exec sensor root 'cat /var/log/suricata/eve.json' > /lab/admin/var/log/lab/remote/sensor/eve.json 2>/dev/null
root admin 'cat feed.txt'
root admin "grep -v '^#' feed.txt | while read a; do jq -r --arg a \$a 'select(.src_ip == \$a) | .src_ip' /var/log/lab/remote/fw/flows.json /var/log/lab/remote/fw/drops.json; done | sort | uniq -c"
root fw 'nft add set ip filter intel "{ type ipv4_addr; flags timeout; timeout 1d; }"'
root fw "nft 'insert rule ip filter forward ip saddr @intel log group 1 prefix \"intel-drop\" drop'"
root fw 'nft add element ip filter intel "{ 203.0.113.50, 198.51.100.23, 198.51.100.140 }"'
root fw 'nft list set ip filter intel'
on remote 'curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://www.example.com/'
on branch 'curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://www.example.com/'
sleep 2
root admin "tail -3 /var/log/lab/remote/fw/drops.json | jq -c '[.src_ip, .dest_port, .\"oob.prefix\"]'"

block correlate
root admin 'python3 correlate.py 203.0.113.50'

block keep
root admin 'cd /var/log/lab/remote; wc -lc fw/flows.json fw/drops.json sensor/eve.json'
root admin 'jq -r .event_type /var/log/lab/remote/sensor/eve.json | sort | uniq -c | sort -rn'
