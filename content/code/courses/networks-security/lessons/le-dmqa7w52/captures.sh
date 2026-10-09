#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of networks-security, as a script that produces them.
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
# root@branch is the administrator on the branch office's router; branchpc and
# guest are computers in the branch office.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with fw routing and filtering nothing,
# so that every filter in this lesson is the branch router's; guest, a second
# computer plugged into the branch segment with lab.sh plug, 192.168.30.99;
# a listener on remote's port 80, standing in for any web server; a route on
# remote back to the branch's addresses through branch, since the lab's branch
# does no address translation; the ACL
# files written to branch before each is shown with cat. The Cisco IOS
# configuration in the lesson is notation and was not run: the lab has no
# Cisco equipment.
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
lab plug guest branch 192.168.30.99/24 52:54:00:1e:63:99 >/dev/null 2>&1; ip -n guest route add default via 192.168.30.1
quiet remote 'ip route add 192.168.30.0/24 via 203.0.113.70'
quiet remote 'setsid socat TCP-LISTEN:80,bind=203.0.113.50,fork,reuseaddr SYSTEM:"echo remote web" </dev/null >/dev/null 2>&1 &'
sleep 0.5

block before
on branchpc 'probe remote:80 remote:443 remote:22'
on guest 'probe remote:80 remote:443'

block standard
quiet branch 'cat > /root/acl-standard.nft <<"NFT"
table netdev acl {
  chain lan_in {
    type filter hook ingress device "eth1" priority filter; policy drop;
    ip saddr 192.168.30.20 accept comment "10: permit host 192.168.30.20"
    meta protocol arp accept comment "(not IP: the segment has to keep working)"
  }
}
NFT'
root branch 'cat acl-standard.nft'
root branch 'nft -f acl-standard.nft'
on branchpc 'probe remote:80 remote:443'
on guest 'probe remote:80 remote:443'
root branch 'nft list chain netdev acl lan_in | grep -E "counter|saddr" ; nft delete table netdev acl'

block extended
quiet branch 'cat > /root/acl-extended.nft <<"NFT"
table netdev acl {
  chain lan_in {
    type filter hook ingress device "eth1" priority filter; policy drop;
    meta protocol arp accept
    ip saddr 192.168.30.0/24 ip daddr 192.168.30.1 accept comment "the router itself"
    ip saddr 192.168.30.0/24 tcp dport { 80, 443 } counter accept comment "10: permit tcp 192.168.30.0 0.0.0.255 any eq www 443"
    ip saddr 192.168.30.0/24 udp dport 53 counter accept comment "20: permit udp 192.168.30.0 0.0.0.255 any eq domain"
    counter comment "the implicit deny, counted"
  }
  chain wan_in {
    type filter hook ingress device "eth0" priority filter; policy accept;
    ip daddr 192.168.30.0/24 tcp flags & (ack | rst) == 0 counter drop comment "no new TCP towards the branch: the IOS established keyword"
  }
}
NFT'
root branch 'cat acl-extended.nft'
root branch 'nft -f acl-extended.nft'
on branchpc 'probe remote:80 remote:443 remote:22'
on guest 'probe remote:80'
root branch 'nft list table netdev acl | grep counter'

block established
quiet branchpc 'setsid socat TCP-LISTEN:8080,bind=192.168.30.20,fork,reuseaddr SYSTEM:"echo branchpc" </dev/null >/dev/null 2>&1 &'
sleep 0.5
on remote 'probe 192.168.30.20:8080'
root branch 'nft list chain netdev acl wan_in | grep counter'
on branchpc 'nc -w1 203.0.113.50 80 </dev/null'

block wildcard
on branch 'python3 -c "import ipaddress as i; n=i.ip_network(\"192.168.30.0/24\"); print(n.netmask, n.hostmask); n=i.ip_network(\"10.20.16.0/20\"); print(n.netmask, n.hostmask, n.num_addresses)"'
