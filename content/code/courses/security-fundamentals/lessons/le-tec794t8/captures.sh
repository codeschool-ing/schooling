#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; the first
# reading of this lesson draws its map. A line that starts with ana@outside ran
# on the machine on the internet, ana@laptop on the office laptop, ana@www on
# the shop's server in the DMZ, and root@fw is the administrator on the firewall.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, with fw forwarding everything and filtering
# nothing; zones.nft, written to fw's root folder by this script and shown in
# the lesson with cat before it is loaded. probe is lab.sh's own: nc -z with
# the result in words. Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
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

block flat
on outside 'probe www:80 db:5432'
on www 'probe db:5432 db:22 laptop:22'
on laptop 'probe www:80 db:5432'

quiet fw 'cat > /root/zones.nft <<"NFT"
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport 80 accept comment "the internet reaches the shop"
    iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.30 tcp dport 5432 accept comment "the shop reaches its database"
    iifname "eth2" oifname { "eth0", "eth1" } accept comment "the office reaches the internet and the shop"
  }
}
NFT'

block rules
root fw 'cat zones.nft'
root fw 'nft -f zones.nft'

block zoned
on outside 'probe www:80 db:5432'
on www 'probe db:5432 db:22 laptop:22'
on laptop 'probe www:80 db:5432'
