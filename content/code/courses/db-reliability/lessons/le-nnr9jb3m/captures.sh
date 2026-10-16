#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of db-reliability, as a script that
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
# from lesson 19's haproxy.cfg, and lesson 19's orders.sh in ana's home.
# rehearsal.sh is taken out of this lesson's .md, so the file the student
# copies is the file that ran.
#
# The waits (`sleep`) are Patroni's: a node stopped with SIGTERM takes a few
# seconds to stop its PostgreSQL, and one started again takes up to thirty to
# rejoin.
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
extract the-script.md rehearsal.sh | lab exec 'cat > rehearsal.sh && chmod +x rehearsal.sh'
lab exec 'haproxy -D -f ~/haproxy/haproxy.cfg'
sleep 6

block abort
on "pkill -TERM -f 'patroni/pg3[.]yml'"
sleep 10
on 'patronictl -c ~/patroni/pg1.yml list'
on './rehearsal.sh; echo "exit $?"'

block healthy
on 'patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &'
sleep 30
on 'patronictl -c ~/patroni/pg1.yml list'

block run
on './rehearsal.sh'
