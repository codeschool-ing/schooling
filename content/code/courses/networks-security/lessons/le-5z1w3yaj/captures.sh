#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of networks-security, as a script that produces them.
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
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw, plus one rule letting the staff LAN reach the signed zone's
# port on dns, 5300; two machines given a second address that is not theirs to use,
# the way a misconfigured host or a forged packet presents a source that does
# not belong where it arrives: remote, on the internet, with 192.168.20.99
# (an address of the company's server range), and laptop with 198.51.100.7
# (an address that belongs to nobody in the lab); a recording on www with
# tcpdump in the background, read afterwards; the DNSSEC half of the lab, which
# lab.sh builds: BIND on dns serving example.com signed, on port 5300, and a
# validating Unbound on laptop's loopback that trusts the zone's key.
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
quiet fw 'nft -f baseline.nft; nft insert rule ip filter forward index 1 iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 5300 ct state new accept comment \"the resolver asks the signed zone\"'
quiet remote 'ip addr add 192.168.20.99/32 dev eth0'
quiet laptop 'ip addr add 198.51.100.7/32 dev eth0'

block forged-in
quiet www 'setsid timeout 6 tcpdump -n -i eth0 -c 1 "tcp dst port 443 and src 192.168.20.99" > /root/syn.txt 2>/dev/null </dev/null &'
sleep 2
on remote 'curl -s -m2 --interface 192.168.20.99 https://www.example.com/; echo "exit $?"'
sleep 1
root www 'cut -d" " -f2-7 syn.txt'

block antispoof
quiet fw 'cat > /root/antispoof.nft <<"NFT"
table ip filter {
  chain prerouting {
    type filter hook prerouting priority filter; policy accept;
    iifname "eth0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter drop comment "private sources never arrive from the internet"
    fib saddr . iif oif missing counter drop comment "the source must be reachable back through the interface it came in on"
  }
}
NFT'
root fw 'cat antispoof.nft'
root fw 'nft -f antispoof.nft'
on remote 'curl -s -m2 --interface 192.168.20.99 https://www.example.com/; echo "exit $?"'
on remote 'curl -s -m2 https://www.example.com/'
root fw 'nft list chain ip filter prerouting | grep counter'

block egress
on laptop 'nc -z -v -w1 -s 198.51.100.7 203.0.113.50 443'
root fw 'nft list chain ip filter prerouting | grep "fib saddr"'
on laptop 'nc -z -v -w1 203.0.113.50 443'

block rpfilter
root fw 'sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.eth0.rp_filter'

block dnssec
on laptop 'grep -E "server:|trust-anchor|stub-addr" /etc/unbound/unbound.conf'
on laptop 'dig +dnssec @127.0.0.1 www.example.com | grep -E "flags:|IN.A|RRSIG"'

block tamper
root dns 'sed -i "s/^\(www\.example\.com\.[[:space:]]*300[[:space:]]*IN A[[:space:]]*\)192.0.2.80/\1203.0.113.66/" /etc/bind/db.example.com.signed; grep -n "IN A" /etc/bind/db.example.com.signed'
quiet dns 'kill $(cat /var/cache/bind/named.pid); sleep 1; named -u bind -c /etc/bind/named.conf; sleep 1'
root laptop 'unbound-control flush www.example.com'
on laptop 'dig @127.0.0.1 www.example.com | grep -E "status|^www"'
root laptop 'grep "validation failure" /var/lib/unbound/unbound.log | cut -d" " -f3-'
on laptop 'dig +cd +short @127.0.0.1 www.example.com'
