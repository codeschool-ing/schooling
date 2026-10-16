#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 19 leaves it, rebuilt quietly:
# `lab.sh base`, etcd as its package starts it (`lab.sh etcd`), the three
# Patroni nodes from lesson 16's pg1.yml, the shop loaded into pg1, HAProxy
# from lesson 19's haproxy.cfg on ports 5000, 5001 and 7000, and lesson 19's
# orders.sh in ana's home. Both files are taken out of lesson 19's .md.
#
# THE INCIDENT IS A kill -9 of pg1's Patroni and PostgreSQL, as lesson 16 did,
# while orders.sh runs. The waits (`sleep`) are Patroni's 30-second ttl and
# orders.sh's 40 seconds.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Patroni 3.2.2, etcd 3.4.30,
# HAProxy 2.8.16, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh
L16=../le-zr1n913d
L19=../le-aqsf7jbk

lab base
lab etcd
lab exec 'mkdir -p ~/patroni ~/haproxy'
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
extract $L19/haproxy.md haproxy.cfg | lab exec 'cat > ~/haproxy/haproxy.cfg'
extract $L19/the-switch.md orders.sh | lab exec 'cat > orders.sh && chmod +x orders.sh'
lab exec 'haproxy -D -f ~/haproxy/haproxy.cfg'
sleep 6

block incident
on './orders.sh > orders.log 2>&1 &'
sleep 8
on "date +%T; pkill -9 -f 'patroni/pg1[.]yml'; kill -9 \$(head -n 1 ~/patroni/pg1/postmaster.pid)"
sleep 45

block detect
on 'grep -c ok orders.log; grep -c FAILED orders.log'
on 'grep -m 1 FAILED orders.log; grep FAILED orders.log | tail -n 1; grep -A 1 FAILED orders.log | tail -n 1'
on 'patronictl -c ~/patroni/pg2.yml list'

block evidence
on 'grep -h -E "promoted self|acquired session lock" ~/patroni/pg2.log ~/patroni/pg3.log'
on "curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^primary,pg'"
on 'psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c "SELECT count(*) FROM orders WHERE id > 50000"'

block recover
on 'patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &'
sleep 30
on 'patronictl -c ~/patroni/pg1.yml list'
