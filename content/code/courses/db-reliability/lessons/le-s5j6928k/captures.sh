#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of db-reliability, as a script that
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
# THE FROZEN LEADER IS A SIGSTOP of pg1's Patroni process, which is what a
# long pause looks like from outside: a virtual machine suspended by its host,
# a process stuck on a dying disk, a garbage-collection pause. Its PostgreSQL
# is not stopped, and that is the point.
#
# The waits (`sleep`) are Patroni's 30-second ttl and 10-second loop.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Patroni 3.2.2, etcd 3.4.30,
# TZ=America/Sao_Paulo.
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
sleep 3

leader_port() { lab exec "patronictl -c ~/patroni/pg1.yml list -f json" | python3 -c 'import json,sys; print([m["Host"].split(":")[1] for m in json.load(sys.stdin) if m["Role"]=="Leader"][0])'; }

block before
on 'patronictl -c ~/patroni/pg1.yml list'

block freeze
on "pkill -STOP -f 'patroni/pg1[.]yml'"
sleep 45
on 'patronictl -c ~/patroni/pg2.yml list'
P=$(leader_port)
on 'psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"'
on "psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (71, 7100, now()) RETURNING id\""
on "psql -h 127.0.0.1 -p $P -U postgres -XAt shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (72, 7200, now()) RETURNING id\""

block thaw
on "pkill -CONT -f 'patroni/pg1[.]yml'"
sleep 40
on 'patronictl -c ~/patroni/pg1.yml list'
on 'grep -h -E "demot|rewind" ~/patroni/pg1.log | tail -n 4'
on 'psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT id, customer_id FROM orders WHERE id > 50000 ORDER BY id"'

block sync-mode
P=$(leader_port)
lab exec "patronictl -c ~/patroni/pg1.yml switchover --candidate pg1 --force > /dev/null 2>&1"
sleep 30
on 'patronictl -c ~/patroni/pg1.yml edit-config --set synchronous_mode=true --force > /dev/null'
sleep 25
on 'patronictl -c ~/patroni/pg1.yml list'

block sync-freeze
on "pkill -STOP -f 'patroni/pg1[.]yml'"
sleep 45
on 'patronictl -c ~/patroni/pg2.yml list'
on "timeout 10 psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (73, 7300, now()) RETURNING id\"; echo \"exit \$?\""
on 'psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SHOW synchronous_standby_names"'
on "pkill -CONT -f 'patroni/pg1[.]yml'"
sleep 40
on 'patronictl -c ~/patroni/pg1.yml list'
