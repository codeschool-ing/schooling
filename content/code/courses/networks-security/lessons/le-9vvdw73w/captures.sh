#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/nslab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@sensor is the administrator on the network sensor in the DMZ; root@www
# is the administrator on the shop's proxy, which gets a host sensor of its
# own in this lesson.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; the network sensor's rule file written before it is shown;
# AIDE's configuration on www, written before it is shown with cat; a pause
# after Suricata starts; the change to the proxy's configuration and the
# listener on port 8081, made between blocks the way an administrator in a
# hurry, or an intruder, would make them.
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
quiet sensor 'cat > /etc/suricata/rules/local.rules <<"R"
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin/"; startswith; classtype:policy-violation; sid:1000101; rev:3;)
R'
quiet sensor 'suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid'
sleep 10

block blind-spot
on remote 'curl -s http://www.example.com/admin/; curl -s https://www.example.com/admin/'
sleep 2
root sensor 'jq -c "select(.event_type==\"alert\") | [.alert.signature_id, .dest_port, .http.url]" /var/log/suricata/eve.json'
root sensor 'jq -c "select(.event_type==\"tls\") | [.src_ip, .dest_port, .tls.sni]" /var/log/suricata/eve.json'
root www 'grep "/admin/" /var/log/nginx/access.log | cut -d" " -f1,4,6-9'

block aide-init
quiet www 'mkdir -p /etc/aide /var/lib/aide; cat > /etc/aide/shop.conf <<"C"
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
report_url=stdout
Watch = p+u+g+s+m+c+sha256
/etc/nginx Watch
/etc/ssl/private Watch
/etc/ssh Watch
C'
root www 'cat /etc/aide/shop.conf'
root www 'aide --config /etc/aide/shop.conf --init | grep -E "^Number|^AIDE"; mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db'
root www 'aide --config /etc/aide/shop.conf --check | grep -E "^AIDE|^Number|found"; echo "exit $?"'

block aide-change
quiet www 'sed -i "s|    location / {|    location /debug/ {\n        proxy_pass http://127.0.0.1:8081;\n    }\n    location / {|" /etc/nginx/sites-enabled/shop'
root www 'aide --config /etc/aide/shop.conf --check > aide.txt; echo "exit $?"; grep -E "^Summary|^ *Total|^ *Changed|^[fd] " aide.txt'
root www 'sed -n "/^File: /,/^$/p" aide.txt | grep -E "^File|Size|Mtime|SHA256"'

block listeners
root www 'ss -Hltn | awk "{print \$4}" | sort > listening.baseline; cat listening.baseline'
quiet www 'setsid socat TCP-LISTEN:8081,bind=0.0.0.0,fork,reuseaddr SYSTEM:"echo debug" </dev/null >/dev/null 2>&1 &'
sleep 1
root www 'ss -Hltn | awk "{print \$4}" | sort | diff listening.baseline -; ss -Hltnp "sport = :8081" | awk "{print \$4, \$6}"'
