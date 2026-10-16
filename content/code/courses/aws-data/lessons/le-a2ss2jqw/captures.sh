#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of aws-data (DMS and change data
# capture), as a script that produces them. Every transcript in the lesson was
# copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S, and this script starts where a student is after "Every
# time you open a terminal", with moto empty. moto 5.2.3 stores DMS instances,
# endpoints and tasks and replicates nothing; the lesson says so beside each.
#
# THE CDC SECTION RUNS A REAL POSTGRESQL 16, Ubuntu's postgresql-16 package, as
# sql-databases lesson 1 installs it. The student runs the throwaway server as
# themselves. The recording machine runs everything as root, and PostgreSQL
# refuses to run as root, so the two sh fences of cdc-for-real.md are run as the
# system user `postgres` with HOME=/home/ana, and ~/aws/cdc is created and
# handed to that user first (STAGED). The PG* variables of the fence's last line
# are exported here for the psql commands, which connect over the socket in
# ~/aws/cdc as the database user `postgres`, exactly as the student's do.
#
# The JSON files the student saves are read out of the lesson by the name that
# introduces each fence.
#
# The secret's password is made by `openssl rand` inside the command and is
# never printed.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran the
# whole sheet once, which is the first step lesson 1's price sheet asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$LESSONS/le-a2ss2jqw"

block dms-instance
run 'aws dms create-replication-instance --replication-instance-identifier quitanda-cdc --replication-instance-class dms.c5.large --allocated-storage 50 --query "ReplicationInstance.[ReplicationInstanceArn,ReplicationInstanceStatus]"'
run 'aws dms describe-replication-instances --query "ReplicationInstances[].[ReplicationInstanceIdentifier,ReplicationInstanceClass,ReplicationInstanceStatus]" --output text'

block dms-source
run 'aws secretsmanager create-secret --name quitanda/legacy-shop --secret-string "{\"username\": \"dms_reader\", \"password\": \"$(openssl rand -hex 16)\", \"host\": \"198.51.100.20\", \"port\": 5432}" --query Name --output text'
run 'aws dms create-endpoint --endpoint-identifier legacy-shop --endpoint-type source --engine-name postgres --database-name shop --postgre-sql-settings SecretsManagerSecretId=quitanda/legacy-shop,SecretsManagerAccessRoleArn=arn:aws:iam::123456789012:role/quitanda-dms-secrets,SlotName=dms_orders,PluginName=test-decoding --query "Endpoint.[EndpointArn,Status,PostgreSQLSettings]"'

block dms-target
run 'aws dms create-endpoint --endpoint-identifier lake-raw --endpoint-type target --engine-name s3 --s3-settings BucketName=quitanda-raw-prod,BucketFolder=cdc,ServiceAccessRoleArn=arn:aws:iam::123456789012:role/quitanda-dms-s3 --query "Endpoint.[EndpointArn,Status]"'
RI=$(aws dms describe-replication-instances --query 'ReplicationInstances[0].ReplicationInstanceArn' --output text)
SRC=$(aws dms describe-endpoints --filters Name=endpoint-id,Values=legacy-shop --query 'Endpoints[0].EndpointArn' --output text)
TGT=$(aws dms describe-endpoints --filters Name=endpoint-id,Values=lake-raw --query 'Endpoints[0].EndpointArn' --output text)
run "aws dms test-connection --replication-instance-arn $RI --endpoint-arn $SRC --query Connection.Status"

file_fence "$L/endpoints-and-tasks.md" mappings.json > mappings.json || exit 1
block dms-task
run "aws dms create-replication-task --replication-task-identifier orders-to-lake --source-endpoint-arn $SRC --target-endpoint-arn $TGT --replication-instance-arn $RI --migration-type full-load-and-cdc --table-mappings file://mappings.json --query 'ReplicationTask.[Status,ReplicationTaskStats]'"
TASK=$(aws dms describe-replication-tasks --filters Name=replication-task-id,Values=orders-to-lake --query 'ReplicationTasks[0].ReplicationTaskArn' --output text)
run "aws dms start-replication-task --replication-task-arn $TASK --start-replication-task-type start-replication --query ReplicationTask.Status"
run "aws dms describe-table-statistics --replication-task-arn $TASK"
run 'aws s3 ls s3://quitanda-raw-prod/cdc/'
run "aws dms stop-replication-task --replication-task-arn $TASK --query ReplicationTask.Status"

block dms-serverless
run "aws dms create-replication-config --replication-config-identifier orders-to-lake-serverless --source-endpoint-arn $SRC --target-endpoint-arn $TGT --replication-type full-load-and-cdc --table-mappings file://mappings.json --compute-config MinCapacityUnits=2,MaxCapacityUnits=16"

file_fence "$L/mappings-and-settings.md" mappings-full.json > mappings-full.json || exit 1
file_fence "$L/mappings-and-settings.md" task-settings.json > task-settings.json || exit 1
printf '{"rules": [\n' > broken.json
block dms-mappings
run "aws dms create-replication-task --replication-task-identifier shop-to-lake --source-endpoint-arn $SRC --target-endpoint-arn $TGT --replication-instance-arn $RI --migration-type full-load-and-cdc --table-mappings file://mappings-full.json --replication-task-settings file://task-settings.json --query ReplicationTask.ReplicationTaskSettings --output text"
run 'cat broken.json'
run "aws dms create-replication-task --replication-task-identifier broken --source-endpoint-arn $SRC --target-endpoint-arn $TGT --replication-instance-arn $RI --migration-type cdc --table-mappings file://broken.json --query 'ReplicationTask.[ReplicationTaskIdentifier,Status,TableMappings]'"
block dms-jsoncheck
run 'python3 -m json.tool broken.json'
run 'python3 -m json.tool mappings-full.json > /dev/null && echo valid'

block price-dms
run 'python3 prices.py dms'

# ---- cdc-for-real: a real PostgreSQL 16, as the student starts it -------------
mkdir -p ~/aws/cdc && chown postgres: ~/aws/cdc
runuser -u postgres -- env HOME=/home/ana bash -e -c "$(fence "$L/cdc-for-real.md" 1)" > /dev/null || exit 1
eval "$(fence "$L/cdc-for-real.md" 1 | grep '^export PG')"
block cdc-setup
run 'psql -c "SHOW wal_level"'
run "psql -c \"CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text NOT NULL, total_cents integer NOT NULL)\" -c \"INSERT INTO orders VALUES ('ord-1', 'c-17', 4590)\""
run "psql -c \"SELECT slot_name, lsn FROM pg_create_logical_replication_slot('dms_orders', 'test_decoding')\""
block cdc-peek
run "psql -c \"INSERT INTO orders VALUES ('ord-2', 'c-03', 12800)\" -c \"UPDATE orders SET total_cents = 4990 WHERE order_id = 'ord-1'\" -c \"DELETE FROM orders WHERE order_id = 'ord-2'\""
run "psql -Atc \"SELECT lsn, xid, data FROM pg_logical_slot_peek_changes('dms_orders', NULL, NULL)\""
block cdc-get
run "psql -Atc \"SELECT data FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)\""
run "psql -Atc \"SELECT count(*) FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)\""
block cdc-identity
run "psql -c \"ALTER TABLE orders REPLICA IDENTITY FULL\" -c \"UPDATE orders SET total_cents = 5190 WHERE order_id = 'ord-1'\""
run "psql -Atc \"SELECT xid, data FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)\""
block cdc-retained
run "psql -c \"INSERT INTO orders SELECT 'bulk-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 20000) g\""
run "psql -c \"SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots\""
run "psql -Atc \"SELECT pg_drop_replication_slot('dms_orders')\" -c \"SELECT count(*) FROM pg_replication_slots\""
runuser -u postgres -- env HOME=/home/ana PG=/usr/lib/postgresql/16/bin bash -c "$(fence "$L/cdc-for-real.md" 2)" > /dev/null 2>&1
# the second line of that fence cannot remove ~/aws/cdc itself here, whose
# parent belongs to root; the throwaway layer over ~ana goes with the run anyway
