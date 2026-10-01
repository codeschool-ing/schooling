#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of networks-security, as a script that produces them.
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
# root@db is the administrator on the database server; ana@admin works from
# the management machine, and admin2 is a second machine plugged into the
# management segment for this lesson.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; an SSH key pair for ana made on admin and its public half
# installed on db, as an administrator would have done once; admin2, plugged
# into the management segment with lab.sh plug, 192.168.99.11, and given a
# copy of the same private key, which is how a copied key behaves; a rule on
# db letting admin2 reach its SSH port, so that the key's own restriction is
# what refuses it; rule files
# written before they are shown with cat.
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
lab plug admin2 mgmt 192.168.99.11/24 52:54:00:a8:63:0b >/dev/null 2>&1; ip -n admin2 route add default via 192.168.99.1
quiet admin 'mkdir -p /home/ana/.ssh; ssh-keygen -q -t ed25519 -N "" -C "ana@admin" -f /home/ana/.ssh/id_ed25519; printf "Host *\n  StrictHostKeyChecking accept-new\n  UserKnownHostsFile /dev/null\n  LogLevel ERROR\n  BatchMode yes\n" > /home/ana/.ssh/config; chown -R ana:ana /home/ana/.ssh'
mkdir -p /lab/db/home/ana/.ssh /lab/admin2/home/ana/.ssh
cp /lab/admin/home/ana/.ssh/id_ed25519 /lab/admin/home/ana/.ssh/id_ed25519.pub /lab/admin/home/ana/.ssh/config /lab/admin2/home/ana/.ssh/
chown -R ana:ana /lab/admin2/home/ana/.ssh; chmod 700 /lab/admin2/home/ana/.ssh

block who-reaches-db
on app 'probe db:5432 db:22'
on laptop 'probe db:5432 db:22'
on admin 'probe db:5432 db:22'

block db-host
quiet db 'cat > /root/host.nft <<"NFT"
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    ip saddr 192.168.20.10 tcp dport 5432 accept comment "the application, and nothing else, uses the database"
    ip saddr 192.168.99.10 tcp dport 22 accept comment "administration from the jump host only"
  }
  chain output {
    type filter hook output priority filter; policy drop;
    ct state established,related accept
    oifname "lo" accept
    comment "the database starts no connections of its own"
  }
}
NFT'
root db 'cat host.nft'
root db 'nft -f host.nft'
on app 'probe db:5432 db:22'
on admin 'probe db:5432 db:22'
on db 'probe app:8080 www:443'

block key-from
quiet db 'mkdir -p /home/ana/.ssh; printf "from=\"192.168.99.10\",no-agent-forwarding,no-port-forwarding,no-X11-forwarding %s\n" "$(cat /lab/admin/home/ana/.ssh/id_ed25519.pub)" > /home/ana/.ssh/authorized_keys; chown -R ana:ana /home/ana/.ssh; chmod 700 /home/ana/.ssh; chmod 600 /home/ana/.ssh/authorized_keys'
root db 'cut -c1-96 /home/ana/.ssh/authorized_keys'
on admin 'ssh db hostname'
quiet db 'nft add rule inet host input ip saddr 192.168.99.11 tcp dport 22 accept'
on admin2 'ssh db hostname; echo "exit $?"'

block expiring
root fw 'nft add set ip filter vendor "{ type ipv4_addr; flags timeout; comment \"temporary support access\"; }"'
root fw "nft insert rule ip filter forward index 1 iifname eth0 ip saddr @vendor ip daddr 192.168.20.10 tcp dport 22 ct state new accept comment '\"vendor support, while in the set\"'"
root fw 'nft add element ip filter vendor "{ 203.0.113.70 timeout 15s }"; nft list set ip filter vendor | grep elements'
on branch 'probe app:22'
sleep 16
root fw 'nft list set ip filter vendor | grep -c elements'
on branch 'probe app:22'
