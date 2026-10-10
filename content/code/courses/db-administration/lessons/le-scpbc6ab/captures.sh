#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 ends, which is where lesson 4 ended: PostgreSQL 16
# from Ubuntu's packages with nothing in conf.d, a superuser role and a
# database for ana, and the shop database (orders: 1,000,000 rows). Everything
# the lesson changes is undone before the end.
#
# STAGED: the recording machine is a container on a computer with 4 processors
# and 15 GB of memory, and it sees all of both; the virtual machine lesson 3
# recommends has 2 and 4 GB. The lesson says which numbers depend on that.
# Timings come from that computer, with the table already in the operating
# system's cache, which is why reading from "disk" and spilling to it cost so
# little here; the lesson says so where it matters.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

lab reset 6

C=/etc/postgresql/16/main

block machine
on 'nproc'
on 'free -h'

block kinds
printf 'ana@db:~$ psql shop\n'
printf "SELECT name, setting, unit, context\n  FROM pg_settings\n WHERE name IN ('shared_buffers', 'shared_memory_size', 'work_mem',\n                'hash_mem_multiplier', 'maintenance_work_mem',\n                'autovacuum_work_mem', 'temp_buffers', 'effective_cache_size')\n ORDER BY name;\n\\\\q\n" | session shop

block buffers
on 'sudo systemctl restart postgresql'
printf 'ana@db:~$ psql shop\n'
printf "CREATE EXTENSION pg_buffercache;\nSELECT buffers_used, buffers_unused FROM pg_buffercache_summary();\nSELECT pg_size_pretty(pg_relation_size('orders')) AS size,\n       pg_relation_size('orders') / 8192 AS pages;\nEXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;\nSELECT c.relname, count(*) AS buffers\n  FROM pg_buffercache b\n  JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)\n WHERE b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())\n GROUP BY c.relname ORDER BY buffers DESC LIMIT 3;\nEXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;\n\\\\q\n" | session shop

block bigger
on "echo 'shared_buffers = 1GB' | sudo tee $C/conf.d/10-memory.conf"
on 'sudo systemctl restart postgresql'
printf 'ana@db:~$ psql shop\n'
printf "SELECT name, setting, unit FROM pg_settings\n WHERE name IN ('shared_buffers', 'shared_memory_size');\nEXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;\nEXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;\nSELECT buffers_used, buffers_unused FROM pg_buffercache_summary();\n\\\\q\n" | session shop

block sort
printf 'ana@db:~$ psql shop\n'
printf "EXPLAIN (ANALYZE, COSTS OFF)\n  SELECT customer_id, total_cents FROM orders ORDER BY total_cents;\nSET work_mem = '100MB';\nEXPLAIN (ANALYZE, COSTS OFF)\n  SELECT customer_id, total_cents FROM orders ORDER BY total_cents;\n\\\\q\n" | session shop

block hash
printf 'ana@db:~$ psql shop\n'
printf "EXPLAIN (ANALYZE, COSTS OFF)\n  SELECT customer_id, sum(total_cents) FROM orders\n   GROUP BY customer_id ORDER BY 2 DESC LIMIT 5;\n\\\\q\n" | session shop

block index
printf 'ana@db:~$ psql shop\n'
printf "\\\\timing on\nSET max_parallel_maintenance_workers = 0;\nSET log_temp_files = 0;\nSET client_min_messages = log;\nSET maintenance_work_mem = '1MB';\nCREATE INDEX orders_total_cents ON orders (total_cents);\nDROP INDEX orders_total_cents;\nRESET maintenance_work_mem;\nSHOW maintenance_work_mem;\nCREATE INDEX orders_total_cents ON orders (total_cents);\nDROP INDEX orders_total_cents;\n\\\\q\n" | session shop

block estimate
printf 'ana@db:~$ psql shop\n'
printf "SET effective_cache_size = '1TB';\nSHOW effective_cache_size;\nRESET effective_cache_size;\nSELECT name, setting FROM pg_settings\n WHERE name IN ('max_connections', 'autovacuum_max_workers',\n                'max_parallel_workers_per_gather');\n\\\\q\n" | session shop

block revert
printf 'ana@db:~$ psql shop\n'
printf "DROP EXTENSION pg_buffercache;\n\\\\q\n" | session shop
on "sudo rm $C/conf.d/10-memory.conf"
on 'sudo systemctl restart postgresql'
printf 'ana@db:~$ psql shop\n'
printf "SELECT name, setting, unit, source FROM pg_settings\n WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem')\n    OR pending_restart;\n\\\\dx\n\\\\q\n" | session shop

lab down
