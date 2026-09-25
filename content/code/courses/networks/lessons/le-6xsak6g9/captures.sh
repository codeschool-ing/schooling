#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of networks, as a script that produces them.
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
# the lab itself, built by lab.sh reset, whose DNS has its own root, its own
# .com and .net, and ns1.example.com answering for example.com, with one
# subdomain, old.example.com, delegated to a server that does not serve it;
# named on ns1 told to reload after the zone is edited, and stopped before
# the server-down block; and the line added to laptop's /etc/hosts removed
# before the nslookup block.
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

lab reset

block resolv
on laptop 'cat /etc/resolv.conf'
on laptop 'getent hosts www.example.com'

block dig
on laptop 'dig www.example.com'

block records
on laptop 'dig +noall +answer example.com A'
on laptop 'dig +noall +answer www.example.com AAAA'
on laptop 'dig +noall +answer shop.example.com'
on laptop 'dig +noall +answer example.com MX'
on laptop 'dig +noall +answer example.com TXT'
on laptop 'dig +noall +answer _dmarc.example.com TXT'
on laptop 'dig +noall +answer example.com NS'
on laptop 'dig +noall +answer example.com SOA'
on laptop 'dig +noall +answer -x 192.0.2.80'

block trace
on laptop 'dig +trace www.example.com'

block referral
on laptop 'dig @192.0.2.10 www.example.com +norecurse'

block authoritative
on laptop 'dig @ns1.example.com www.example.com +norecurse +noall +comments +answer | grep -E "flags|IN"'
on laptop 'dig www.example.com +noall +comments +answer | grep -E "flags|IN"'

block ttl
on laptop 'dig +noall +answer www.example.com'
sleep 5
on laptop 'dig +noall +answer www.example.com'

block change
on ns1 'grep -E "^www|SOA" /etc/bind/db.example.com'
on ns1 "sudo sed -i 's/2026092501/2026092502/; s/^www    300   A      192.0.2.80/www    300   A      192.0.2.81/' /etc/bind/db.example.com"
on ns1 'sudo named-checkzone example.com /etc/bind/db.example.com'
quiet ns1 'for p in $(ip netns pids ns1); do [ "$(cat /proc/$p/comm)" = named ] && kill -HUP $p; done'
sleep 1
on laptop 'dig @ns1.example.com +noall +answer www.example.com'
on laptop 'dig +noall +answer www.example.com'

block flush
on resolver 'sudo unbound-control -c /etc/unbound/unbound.conf flush www.example.com'
on laptop 'dig +noall +answer www.example.com'

block nxdomain
on laptop 'dig ww.example.com | grep -E "status|SOA"'

block nodata
on laptop 'dig mail.example.com AAAA | grep -E "status|ANSWER:"'

block refused
on laptop 'dig @192.0.2.53 www.example.org | grep -E "status|WARNING"'

block hosts
on laptop 'grep hosts /etc/nsswitch.conf'
on laptop 'echo "192.0.2.99 www.example.com" | sudo tee -a /etc/hosts'
on laptop 'getent hosts www.example.com'
on laptop 'dig +short www.example.com'
on laptop 'curl -sS -m 3 https://www.example.com/'

block nslookup
quiet laptop "sed -i '/www.example.com/d' /etc/hosts"
on laptop 'nslookup www.example.com'
on laptop 'nslookup -type=mx example.com'

block servfail
on laptop 'dig old.example.com | grep -E "status|Query time"'
on laptop 'dig @192.0.2.20 old.example.com +norecurse | grep -E "status|flags|IN"'

block server-down
quiet ns1 'for p in $(ip netns pids ns1); do [ -e /proc/$p/comm ] && [ "$(cat /proc/$p/comm)" = named ] && kill $p; done'
on laptop 'dig @192.0.2.53 www.example.com +tries=1 +time=2'

lab down
