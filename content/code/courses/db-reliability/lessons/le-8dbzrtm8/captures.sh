#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from `lab.sh base` and the role replicator of lesson 11. No standby
# is carried over: this lesson's second server is PostgreSQL 17, run by Docker
# from the official image `postgres:17` with Ubuntu's docker.io package, as the
# lesson shows. THERE IS NO systemd IN THE SANDBOX, so when the Docker daemon is
# not running this script starts `dockerd` itself, which is what the package's
# unit does on the student's machine. The image was pulled before recording;
# the lesson's `docker run` pulls it the first time.
#
# The container uses the host's network (`--network host`), so the two servers
# reach each other on 127.0.0.1 as every other server in the course does; on
# two machines the address would be the publisher's. The waits (`sleep`) give
# the subscription time to copy and to apply.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15 and 17.11, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

if ! docker info >/dev/null 2>&1; then
  (setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &)
  for _ in $(seq 1 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
fi
lab base
printf "CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'replica-pass-1';\n" | lab psql shop >/dev/null

block wal-level
printf "ALTER SYSTEM SET wal_level = logical;\n" | session shop
on 'sudo pg_ctlcluster 16 main restart'
on 'psql -XAt shop -c "SHOW wal_level"'

block publish
printf "CREATE PUBLICATION shop_pub FOR TABLE customers, orders;\nGRANT SELECT ON customers, orders TO replicator;\n" | session shop

block run17
on 'sudo docker run -d --name pg17 --network host -e POSTGRES_PASSWORD=pg17-pass-1 postgres:17 -c port=5440 > /dev/null'
sleep 6
on "echo '127.0.0.1:5440:*:postgres:pg17-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass"
on 'psql -h 127.0.0.1 -p 5440 -U postgres -XAt -c "SELECT version()"'

block schema
on 'psql -h 127.0.0.1 -p 5440 -U postgres -c "CREATE DATABASE shop"'
on 'pg_dump --schema-only --no-owner --no-privileges --no-publications shop | psql -q -o /dev/null -h 127.0.0.1 -p 5440 -U postgres shop'
on 'psql -h 127.0.0.1 -p 5440 -U postgres shop -c "\dt"'

block subscribe
printf "CREATE SUBSCRIPTION shop_sub CONNECTION 'host=127.0.0.1 port=5432 dbname=shop user=replicator password=replica-pass-1' PUBLICATION shop_pub;\n" | session shop -h 127.0.0.1 -p 5440 -U postgres
sleep 6
printf "SELECT count(*) FROM orders;\nSELECT subname, received_lsn, latest_end_lsn FROM pg_stat_subscription;\n" | session shop -h 127.0.0.1 -p 5440 -U postgres

block flowing
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (41, 4100, now()) RETURNING id;\nSELECT slot_name, plugin, slot_type, active FROM pg_replication_slots;\n" | session shop
sleep 2
printf "SELECT id, customer_id, total_cents FROM orders ORDER BY id DESC LIMIT 1;\n" | session shop -h 127.0.0.1 -p 5440 -U postgres

block ddl
printf "ALTER TABLE orders ADD COLUMN note text;\nINSERT INTO orders (customer_id, total_cents, placed_at, note) VALUES (42, 4200, now(), 'gift wrap');\n" | session shop
sleep 4
on 'sudo docker logs pg17 2>&1 | grep ERROR | tail -n 2'
printf "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS held FROM pg_replication_slots;\n" | session shop

block ddl-fix
printf "ALTER TABLE orders ADD COLUMN note text;\n" | session shop -h 127.0.0.1 -p 5440 -U postgres
sleep 6
printf "SELECT id, total_cents, note FROM orders ORDER BY id DESC LIMIT 2;\n" | session shop -h 127.0.0.1 -p 5440 -U postgres

block sequence
on 'psql -XAt shop -c "SELECT last_value FROM orders_id_seq"'
on 'psql -h 127.0.0.1 -p 5440 -U postgres -XAt shop -c "SELECT last_value FROM orders_id_seq"'
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (43, 4300, now());\n" | session shop -h 127.0.0.1 -p 5440 -U postgres

block filter
printf "CREATE PUBLICATION recife_pub FOR TABLE customers WHERE (city = 'Recife');\n" | session shop
on 'psql -h 127.0.0.1 -p 5440 -U postgres -c "CREATE DATABASE recife"'
on 'pg_dump --schema-only --no-owner --no-privileges -t customers shop | psql -q -o /dev/null -h 127.0.0.1 -p 5440 -U postgres recife'
printf "CREATE SUBSCRIPTION recife_sub CONNECTION 'host=127.0.0.1 port=5432 dbname=shop user=replicator password=replica-pass-1' PUBLICATION recife_pub;\n" | session recife -h 127.0.0.1 -p 5440 -U postgres
sleep 6
printf "SELECT city, count(*) FROM customers GROUP BY city;\n" | session recife -h 127.0.0.1 -p 5440 -U postgres

block switch
printf "SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind FROM pg_replication_slots WHERE slot_name = 'shop_sub';\n" | session shop
shell <<'SH'
max=$(psql -XAt shop -c "SELECT max(id) FROM orders")
echo $max
psql -h 127.0.0.1 -p 5440 -U postgres -XAt shop -c "SELECT setval('orders_id_seq', $max + 1000)"
SH
printf "ALTER SUBSCRIPTION shop_sub DISABLE;\nINSERT INTO orders (customer_id, total_cents, placed_at) VALUES (43, 4300, now()) RETURNING id;\n" | session shop -h 127.0.0.1 -p 5440 -U postgres
