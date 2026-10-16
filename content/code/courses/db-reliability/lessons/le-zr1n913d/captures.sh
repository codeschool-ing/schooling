#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from `lab.sh base` (16/main on 5432 with the shop, and shop.sql in
# ana's home) and etcd started as its package's unit starts it (`lab.sh etcd`).
# pg1.yml is taken out of this lesson's .md, so the file the student copies is
# the file that ran.
#
# THERE IS NO systemd HERE. The lesson tells the student to stop and start etcd
# with systemctl; this machine stops the same process with `pkill -x etcd`,
# which is what the transcript shows, and starts it again with `lab.sh etcd`.
#
# The waits (`sleep`) are Patroni's own timings: a 30-second ttl and a
# 10-second loop, so a failover takes up to forty seconds to be decided.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, Patroni 3.2.2, etcd 3.4.30,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
lab etcd
lab exec 'mkdir -p ~/patroni'
extract three-nodes.md pg1.yml | lab exec 'cat > ~/patroni/pg1.yml'

block etcd
on 'etcdctl endpoint health'

block configs
on "sed -e 's/pg1/pg2/g' -e 's/8008/8009/g' -e 's/5441/5442/g' ~/patroni/pg1.yml > ~/patroni/pg2.yml"
on "sed -e 's/pg1/pg3/g' -e 's/8008/8010/g' -e 's/5441/5443/g' ~/patroni/pg1.yml > ~/patroni/pg3.yml"
on 'grep -E "name:|listen:|data_dir:" ~/patroni/pg3.yml'

block start
on 'patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &'
sleep 20
on 'patroni ~/patroni/pg2.yml > ~/patroni/pg2.log 2>&1 &'
on 'patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &'
sleep 30
on 'patronictl -c ~/patroni/pg1.yml list'

block shop
on "echo '127.0.0.1:*:*:postgres:patroni-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass"
on 'createdb -h 127.0.0.1 -p 5441 -U postgres shop'
on 'psql -h 127.0.0.1 -p 5441 -U postgres -q -f shop.sql shop'
sleep 2
on 'psql -h 127.0.0.1 -p 5443 -U postgres -XAt shop -c "SELECT count(*) FROM orders"'

block keys
on 'etcdctl get --prefix --keys-only /service/shop/'
on 'etcdctl get --print-value-only /service/shop/leader'

block kill
shell <<'SH'
date +%T
pkill -9 -f 'patroni/pg1[.]yml'; kill -9 $(head -n 1 ~/patroni/pg1/postmaster.pid)
patronictl -c ~/patroni/pg2.yml list
SH
sleep 45
shell <<'SH'
date +%T
patronictl -c ~/patroni/pg2.yml list
grep -h -E "promoted self|acquired session lock" ~/patroni/pg2.log ~/patroni/pg3.log
SH

block return
on 'patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &'
sleep 30
on 'patronictl -c ~/patroni/pg1.yml list'
on 'grep -E "rewind" ~/patroni/pg1.log | head -n 3'

block switchover
LEADER=$(lab exec "patronictl -c ~/patroni/pg1.yml list -f json" | python3 -c 'import json,sys; print([m["Member"] for m in json.load(sys.stdin) if m["Role"]=="Leader"][0])')
on "patronictl -c ~/patroni/pg1.yml switchover --leader $LEADER --candidate pg1 --force"
sleep 20
on 'patronictl -c ~/patroni/pg1.yml list'

block etcd-down
on 'sudo pkill -x etcd'
sleep 45
on 'timeout 20 patronictl -c ~/patroni/pg1.yml list > /dev/null 2>&1; echo "exit $?"'
on 'grep -h -E "demot|read-only|failsafe" ~/patroni/pg1.log | tail -n 3'
on 'psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"'
on "psql -h 127.0.0.1 -p 5441 -U postgres shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (61, 6100, now())\""
lab etcd
sleep 30
on 'patronictl -c ~/patroni/pg1.yml list'

block failsafe
on 'patronictl -c ~/patroni/pg1.yml edit-config --set failsafe_mode=true --force'
sleep 15
on 'sudo pkill -x etcd'
sleep 45
on 'psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"'
on "psql -h 127.0.0.1 -p 5441 -U postgres shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (62, 6200, now())\""
on 'grep -h "failsafe" ~/patroni/pg1.log | tail -n 2'
lab etcd
sleep 20
