#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of networks-security, as a script that produces them.
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
# the lab itself, built by lab.sh reset; probe, the lab's connection tester;
# a second service started on db, port 6379, before the allowlist block, the
# way a new piece of software arrives on a server without anybody telling the
# firewall; the rule files on fw written between blocks, each shown with cat
# before it is loaded.
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

block blocklist
quiet fw 'cat > /root/blocklist.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy accept;
    iifname "eth0" tcp dport { 23, 445, 3389 } drop comment "ports we know are dangerous"
    iifname "eth0" tcp dport 5432 drop comment "the database"
  }
}
NFT'
root fw 'cat blocklist.nft'
root fw 'nft -f blocklist.nft'
on remote 'probe db:5432 app:22 app:8080'
quiet db 'setsid socat TCP-LISTEN:6379,bind=192.168.20.30,fork,reuseaddr SYSTEM:"echo cache ready" </dev/null >/dev/null 2>&1 &'
sleep 0.5
on remote 'probe db:6379'

block allowlist
root fw 'nft -f baseline.nft'
on remote 'probe db:5432 app:22 app:8080 db:6379 www:443'

block check
quiet fw 'sed "s/ct state new accept comment \"staff browse\"/ct state new acept comment \"staff browse\"/" baseline.nft > typo.nft'
root fw 'nft -c -f typo.nft; echo "exit $?"'
root fw 'nft list ruleset | grep -c accept'
root fw 'nft -f typo.nft; echo "exit $?"'
root fw 'nft list ruleset | grep -c accept'

block lockout
quiet fw 'cat > /root/tighter.nft <<"NFT"
flush ruleset
table ip filter {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
  }
}
NFT'
root fw 'nft list ruleset > known-good.nft; wc -l known-good.nft'
root fw '(sleep 5; nft -f known-good.nft; echo "rolled back at $(date +%T)" > rollback.log) > /dev/null 2>&1 & nft -f tighter.nft; date +%T; nft list ruleset | grep -c accept'
on admin 'probe fw:22'
sleep 6
root fw 'cat rollback.log; nft list ruleset | grep -c accept'
root fw 'nft list chain ip filter input'

block rollback-fix
root fw 'nft -f baseline.nft; { echo "flush ruleset"; nft list ruleset; } > known-good.nft; head -3 known-good.nft'
root fw 'nft -f known-good.nft; nft list ruleset | grep -c accept'

block input
root fw 'nft list chain ip filter input'
on laptop 'ping -c1 -W1 192.168.10.1 | tail -2'
on laptop 'probe fw:22'
on admin 'probe fw:22'

block icmp
quiet fw 'nft add rule ip filter input icmp type { echo-request, destination-unreachable, time-exceeded } limit rate 10/second accept comment \"ping and the errors path discovery needs\"'
root fw 'nft list chain ip filter input | grep icmp'
on laptop 'ping -c1 -W1 192.168.10.1 | tail -2'

block log
quiet fw 'nft add rule ip filter forward limit rate 5/second log group 1 prefix \"fw-drop \" comment \"what the policy is about to drop\"'
root fw 'nft list chain ip filter forward | tail -3'
quiet fw 'setsid timeout 10 tcpdump -n -l -i nflog:1 -c 3 > /root/drops.txt 2>/dev/null </dev/null &'
sleep 3
on remote 'probe db:5432 app:22'
on laptop 'probe db:6379'
sleep 2
root fw 'cat drops.txt'

block inet
root fw 'nft list tables'
quiet fw 'sed "s/^table ip filter/table inet filter/" baseline.nft > baseline-inet.nft'
root fw 'nft -c -f baseline-inet.nft && echo "inet rule set: ok"'

block sets
quiet fw 'cat > /root/sets.nft <<"NFT"
table ip filter {
  set admins {
    type ipv4_addr
    elements = { 192.168.99.10 }
    comment "machines allowed to administer servers"
  }
  set admin_ports {
    type inet_service
    elements = { 22, 9100 }
  }
}
NFT'
root fw 'cat sets.nft'
root fw 'nft -f sets.nft && nft insert rule ip filter forward index 2 ip saddr @admins oifname "eth3" tcp dport @admin_ports ct state new accept comment \"administration, by set\"'
root fw 'nft list chain ip filter forward | grep "@admins"'
root fw 'nft add element ip filter admins { 192.168.99.11 } && nft list set ip filter admins | grep elements'
