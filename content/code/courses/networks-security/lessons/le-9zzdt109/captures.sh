#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of networks-security, as a script that produces them.
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
# root@sensor is the administrator on the intrusion detection sensor, plugged
# into the DMZ with no address; root@ips is the administrator on ips, a
# machine with two interfaces and no address, put inline on the DMZ's link to
# fw by lab.sh inline for the second half of the lesson.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; the rule file on each machine written before it is shown with
# cat; a page named admin-guide.html added to the application's pages, as a
# help page a shop might publish; the recording of a sensor's alerts read after
# a few seconds, since Suricata writes them as they happen; lab.sh inline,
# which rewires fw's DMZ cable through ips and writes inline.yaml, Suricata's
# settings for joining its two interfaces.
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
quiet app 'printf "how to use the admin console\n" > /srv/app/admin-guide.html'

block ids-rule
quiet sensor 'cat > /etc/suricata/rules/local.rules <<"R"
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin"; startswith; classtype:policy-violation; sid:1000101; rev:1;)
R'
root sensor 'cat /etc/suricata/rules/local.rules'
root sensor 'suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid'
sleep 9

block ids-sees
on remote 'curl -s http://www.example.com/admin/'
sleep 2
root sensor 'cat /var/log/suricata/fast.log'

block ids-alert
root sensor 'jq "select(.event_type==\"alert\") | {timestamp, src_ip, dest_ip, dest_port, alert: {action: .alert.action, signature_id: .alert.signature_id, signature: .alert.signature, category: .alert.category}, http: {hostname: .http.hostname, url: .http.url, status: .http.status}}" /var/log/suricata/eve.json'
quiet sensor 'kill -INT $(cat /var/log/suricata/suricata.pid)'

block inline
lab inline >/dev/null 2>&1
root ips 'ip -br link'
on remote 'curl -s -m3 http://www.example.com/; echo "exit $?"'
quiet ips 'cat > /etc/suricata/rules/local.rules <<"R"
drop http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin"; startswith; classtype:policy-violation; sid:1000101; rev:2;)
R'
root ips 'cat /etc/suricata/rules/local.rules'
root ips 'suricata -c /etc/suricata/suricata.yaml --include /etc/suricata/inline.yaml --af-packet -D --pidfile /var/log/suricata/suricata.pid'
sleep 10

block ips-blocks
on remote 'curl -s -m3 http://www.example.com/; echo "exit $?"'
on remote 'curl -s -m3 http://www.example.com/admin/; echo "exit $?"'
sleep 1
root ips 'jq -c "select(.event_type==\"alert\") | [.alert.action, .alert.signature_id, .src_ip, .http.url]" /var/log/suricata/eve.json'

block false-positive
on remote 'curl -s -m3 http://www.example.com/admin-guide.html; echo "exit $?"'
sleep 1
root ips 'jq -c "select(.event_type==\"alert\") | [.alert.action, .alert.signature_id, .src_ip, .http.url]" /var/log/suricata/eve.json | tail -1'

block fail-closed
root ips 'kill -INT $(cat /var/log/suricata/suricata.pid); sleep 2; pgrep -c suricata'
on remote 'curl -s -m3 http://www.example.com/; echo "exit $?"'
