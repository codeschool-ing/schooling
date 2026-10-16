#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 16 leaves its first sections, rebuilt
# quietly: `lab.sh base`, etcd as its package starts it (`lab.sh etcd`), the
# three Patroni nodes pg1 to pg3 from lesson 16's pg1.yml and the same two sed
# commands, pg1 started first so that it is the leader, and the shop loaded
# into it with the postgres password in ~/.pgpass.
#
# HAProxy 2.8 is Ubuntu's package; the lesson runs its own instance as ana,
# which is what this script runs. haproxy.cfg and orders.sh are taken out of
# this lesson's .md, so the files the student copies are the files that ran.
#
# The waits (`sleep`) give HAProxy's checks (every 2 s, two in a row) and
# Patroni's switchover time to settle.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Patroni 3.2.2, etcd 3.4.30,
# HAProxy 2.8.16, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh
L16=../le-zr1n913d

lab base
lab etcd
lab exec 'mkdir -p ~/patroni'
extract $L16/three-nodes.md pg1.yml | lab exec 'cat > ~/patroni/pg1.yml'
lab exec "sed -e 's/pg1/pg2/g' -e 's/8008/8009/g' -e 's/5441/5442/g' ~/patroni/pg1.yml > ~/patroni/pg2.yml"
lab exec "sed -e 's/pg1/pg3/g' -e 's/8008/8010/g' -e 's/5441/5443/g' ~/patroni/pg1.yml > ~/patroni/pg3.yml"
lab exec 'patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &'
sleep 20
lab exec 'patroni ~/patroni/pg2.yml > ~/patroni/pg2.log 2>&1 &'
lab exec 'patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &'
sleep 30
lab exec "echo '127.0.0.1:*:*:postgres:patroni-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass"
lab exec 'createdb -h 127.0.0.1 -p 5441 -U postgres shop && psql -h 127.0.0.1 -p 5441 -U postgres -q -f shop.sql shop > /dev/null 2>&1'
lab exec 'mkdir -p ~/haproxy'
extract haproxy.md haproxy.cfg | lab exec 'cat > ~/haproxy/haproxy.cfg'
extract the-switch.md orders.sh | lab exec 'cat > orders.sh && chmod +x orders.sh'
sleep 3

block multihost
on "psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=read-write' -XAt -c 'SELECT inet_server_port()'"
on "psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=standby' -XAt -c 'SELECT inet_server_port()'"

block rest
on 'for p in 8008 8009 8010; do curl -s -o /dev/null -w "$p %{http_code}\n" http://127.0.0.1:$p/primary; done'

block haproxy-start
on 'haproxy -D -f ~/haproxy/haproxy.cfg'
sleep 6
on "curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^(primary|replicas),pg'"
on "psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c 'SELECT inet_server_port(), pg_is_in_recovery()'"
on "psql -h 127.0.0.1 -p 5001 -U postgres -XAt shop -c 'SELECT inet_server_port(), pg_is_in_recovery()'"
on "psql -h 127.0.0.1 -p 5001 -U postgres -XAt shop -c 'SELECT inet_server_port(), pg_is_in_recovery()'"

block held
on "psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c 'SELECT inet_server_port()' -c 'SELECT pg_sleep(30)' -c 'SELECT inet_server_port()' > held.log 2>&1 &"
sleep 2
on './orders.sh > orders.log 2>&1 &'
sleep 8
on 'patronictl -c ~/patroni/pg1.yml switchover --leader pg1 --candidate pg2 --force > /dev/null 2>&1'
sleep 40

block app
on 'cat orders.log'

block held-result
on 'cat held.log'

block after
on "curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^primary,pg'"
on "psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=read-write' -XAt -c 'SELECT inet_server_port()'"
