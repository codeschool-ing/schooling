#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of networks-security, as a script that produces them.
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
# root@admin is where the policy is kept and the host rules are generated;
# root@app and root@db are the administrators on the two servers.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; policy.txt and segment.py written to admin, both shown whole
# in the lesson; each generated rule file copied from admin to its server, as
# a configuration management tool would; on db, the one-line database
# stand-in replaced by a listener that keeps a connection open and repeats
# what it is sent, as a database keeps a client's session; a background client
# on app, sending one line, waiting six seconds, and sending another; before
# the last block, app's database rule put back on db so the session can be
# opened again.
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
quiet admin 'cat > /root/policy.txt <<"P"
# host   address        role    accepts     on port   from roles
app      192.168.20.10  app     http        8080      proxy
db       192.168.20.30  db      postgres    5432      app
www      192.0.2.80     proxy   -           -         -
admin    192.168.99.10  admin   -           -         -
*        -              -       ssh         22        admin
P'
quiet admin 'cat > /root/segment.py <<"PY"
import sys

rows = [l.split() for l in open("policy.txt") if l.strip() and not l.startswith("#")]
address = {r[2]: [] for r in rows if r[2] != "-"}
for r in rows:
    if r[2] != "-":
        address[r[2]].append(r[1])

host = sys.argv[1]
mine = [r for r in rows if r[0] in (host, "*") and r[3] != "-"]

print("flush ruleset\ntable inet host {\n  chain input {")
print("    type filter hook input priority filter; policy drop;")
print("    ct state established,related accept\n    iifname \"lo\" accept")
for _, _, _, service, port, sources in mine:
    peers = ", ".join(a for role in sources.split(",") for a in address[role])
    print(f"    ip saddr {{ {peers} }} tcp dport {port} accept comment \"{service} from {sources}\"")
print("  }\n}")
PY'

block policy
root admin 'cat policy.txt'
root admin 'python3 segment.py db'
root admin 'python3 segment.py app | grep accept'
for h in app db; do bash "$LAB_SH" exec admin root "python3 segment.py $h" > /lab/$h/root/segment.nft; done
root db 'nft -f segment.nft && nft list chain inet host input | grep -c accept'
root app 'nft -f segment.nft && nft list chain inet host input | grep -c accept'

block east-west
on app 'probe db:5432 db:22'
on db 'probe app:8080 app:22'
on www 'probe app:8080 db:5432'
on admin 'probe app:22 db:22 db:5432'

block live-session
quiet db 'kill $(ss -Hltnp "sport = :5432" | grep -o "pid=[0-9]*" | cut -d= -f2); sleep 0.3; setsid socat TCP-LISTEN:5432,bind=192.168.20.30,fork,reuseaddr EXEC:cat </dev/null >/dev/null 2>&1 &'
sleep 0.5
quiet app 'rm -f /root/client.out; setsid bash -c "(echo first; sleep 6; echo second; sleep 1) | nc -N -w8 192.168.20.30 5432 > /root/client.out" </dev/null >/dev/null 2>&1 &'
sleep 2
root db 'conntrack -L -p tcp --dport 5432 2>/dev/null | grep ESTABLISHED | sed "s/ src=192.168.20.30.*//"'
root db "sed -i 's/ip saddr { 192.168.20.10 } tcp dport 5432 accept.*/# app withdrawn from the database, ticket 6203/' segment.nft && nft -f segment.nft && nft list chain inet host input | grep -c 5432"
sleep 6
root app 'cat client.out'

block cut
quiet app 'rm -f /root/client.out'
quiet db 'nft -f /dev/stdin <<<"$(sed "s/# app withdrawn from the database, ticket 6203/ip saddr { 192.168.20.10 } tcp dport 5432 accept/" /root/segment.nft)"'
quiet app 'setsid bash -c "(echo first; sleep 6; echo second; sleep 1) | nc -N -w8 192.168.20.30 5432 > /root/client.out" </dev/null >/dev/null 2>&1 &'
sleep 2
root db 'nft -f segment.nft && conntrack -D -p tcp --dport 5432 -s 192.168.20.10 -u ASSURED 2>&1 >/dev/null'
sleep 6
root app 'cat client.out'
root db 'conntrack -L -p tcp --dport 5432 2>/dev/null | grep ESTABLISHED | sed "s/ src=192.168.20.30.*//"'
