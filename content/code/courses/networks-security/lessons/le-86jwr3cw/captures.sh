#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of networks-security, as a script that produces them.
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
# loaded on fw; the rule file of the per-source limit written to fw and shown
# with cat before it is loaded, its rule then moved to the top of the forward
# chain, where lesson 18 explains it has to be. Every load the lesson puts on the lab is a
# handful of connections from one machine, enough to see a limit act and far
# below anything that would stress a real server.
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

block syncookies
root www 'sysctl net.ipv4.tcp_syncookies net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_synack_retries'

block halfopen
root fw 'sysctl net.netfilter.nf_conntrack_tcp_timeout_syn_sent net.netfilter.nf_conntrack_tcp_timeout_syn_recv net.netfilter.nf_conntrack_tcp_timeout_established'
root fw 'sysctl -w net.netfilter.nf_conntrack_tcp_timeout_syn_recv=20'

block conncount
quiet fw 'cat > /root/perclient.nft <<"NFT"
table ip filter {
  set web_clients {
    type ipv4_addr
    flags dynamic
    size 65535
  }
  chain forward {
    iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter reject with tcp reset comment "at most 4 open connections per client"
  }
}
NFT'
root fw 'cat perclient.nft'
quiet fw 'nft -f perclient.nft; h=$(nft -a list chain ip filter forward | grep "at most 4" | grep -o "handle [0-9]*" | cut -d" " -f2); nft delete rule ip filter forward handle $h; nft insert rule ip filter forward index 1 iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter reject with tcp reset comment \"at most 4 open connections per client\"'
root fw 'nft list chain ip filter forward | sed -n "3,5p"'
on remote 'for i in 1 2 3 4 5 6; do exec {fd}<>/dev/tcp/www.example.com/443 && echo "connection $i: open" || echo "connection $i: refused"; done; sleep 1'
on branch 'exec {fd}<>/dev/tcp/www.example.com/443 && echo "branch: open"'
root fw 'nft list chain ip filter forward | grep "at most 4"'

block afterwards
sleep 2
on remote 'curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/'

block resolver
on remote 'dig @192.0.2.53 www.example.com +qr | grep -E "status|QUERY SIZE|MSG SIZE"'
on remote 'dig @192.0.2.53 example.org | grep -E "status|MSG SIZE"'

block watching
root fw 'conntrack -C; sysctl -n net.netfilter.nf_conntrack_max'
root fw 'conntrack -S | head -2'
