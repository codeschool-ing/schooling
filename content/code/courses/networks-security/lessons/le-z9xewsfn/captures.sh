#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of networks-security, as a script that produces them.
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
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; a listener on desk's port 445 standing in for a Windows file
# share, and on 3389 for remote desktop; the query log of the name server,
# which lab.sh turns on; names under .test, a top-level domain reserved so
# that no real site can ever answer to them.
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
quiet desk 'for p in 445 3389; do setsid socat TCP-LISTEN:$p,bind=192.168.10.21,fork,reuseaddr SYSTEM:"echo desk $p" </dev/null >/dev/null 2>&1 & done'
sleep 0.5

block protective-dns
quiet dns 'cat >> /etc/dnsmasq.d/lab.conf <<"CONF"
# names the company refuses to resolve for its staff: reported phishing and
# lookalikes of its own domain
address=/example-support.test/
address=/example.com.login-verify.test/
CONF
kill $(cat /var/log/lab/dnsmasq.pid); sleep 0.5; dnsmasq --conf-dir=/etc/dnsmasq.d --pid-file=/var/log/lab/dnsmasq.pid --user=root'
root dns 'grep -A3 "^# names the company" /etc/dnsmasq.d/lab.conf'
on laptop 'dig +short www.example.com; dig www.example-support.test | grep status'
on desk 'dig example.com.login-verify.test | grep status'
root dns 'grep -E "example-support|login-verify" /var/log/lab/dnsmasq.log | cut -d" " -f5-'

block lateral
on laptop 'probe desk:445 desk:3389'
quiet desk 'cat > /root/host.nft <<"NFT"
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    icmp type echo-request limit rate 5/second accept
    ip saddr 192.168.99.0/24 tcp dport { 22, 3389 } accept comment "support works from the management segment"
  }
}
NFT'
root desk 'cat host.nft'
root desk 'nft -f host.nft'
on laptop 'probe desk:445 desk:3389'
on desk 'curl -s https://www.example.com/'

block quarantine
quiet fw 'printf "%s\n" "insert rule ip filter forward ip saddr 192.168.10.21 counter drop comment \"quarantine: desk, ticket 4711\"" > /root/quarantine.nft'
root fw 'cat quarantine.nft; nft -f quarantine.nft'
on desk 'curl -s -m3 https://www.example.com/; echo "exit $?"'
on desk 'dig +short +time=1 +tries=1 www.example.com'
on laptop 'curl -s https://www.example.com/'
root fw 'nft list chain ip filter forward | grep quarantine'
