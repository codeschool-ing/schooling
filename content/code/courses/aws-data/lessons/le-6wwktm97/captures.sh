#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of aws-data (Multi-AZ, read replicas
# and point-in-time recovery), as a script that produces them. Every transcript
# in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal": moto empty on 4567, the four lines exported. moto is restarted
# between sections, so each one starts from an empty AWS and rebuilds the
# instance it needs with the first command it shows.
#
# NOTHING HERE REPLICATES, FAILS OVER OR RESTORES. moto stores the records and
# answers in the shape AWS documents; the lesson says so beside each block, and
# teaches the timings from AWS's documentation, not from these runs.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran
# the whole sheet once, which is the first step lesson 1's price sheet asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1

CREATE='aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7'

# ---- multi-az -----------------------------------------------------------------
block maz-create
run "$CREATE --multi-az --query 'DBInstance.[DBInstanceStatus,MultiAZ,AvailabilityZone,SecondaryAvailabilityZone]' --output text"
block maz-failover
run "aws rds reboot-db-instance --db-instance-identifier quitanda-orders --force-failover --query 'DBInstance.[DBInstanceStatus,AvailabilityZone]' --output text"
run "aws rds describe-events --source-type db-instance --source-identifier quitanda-orders --query 'Events[].Message'"
block price-rds
run 'python3 prices.py rds'
moto_stop; moto_start

# ---- multi-az-cluster ---------------------------------------------------------
block mazc-create
run "aws rds create-db-cluster --db-cluster-identifier quitanda-orders --engine postgres --engine-version 16 --db-cluster-instance-class db.m6gd.large --storage-type io2 --allocated-storage 100 --iops 3000 --master-username quitanda --manage-master-user-password --query 'DBCluster.[Status,MultiAZ,Endpoint,ReaderEndpoint]' --output text"
run "aws rds describe-db-clusters --db-cluster-identifier quitanda-orders --query 'DBClusters[0].[Status,MultiAZ,length(DBClusterMembers)]' --output text"
moto_stop; moto_start

# ---- read-replicas ------------------------------------------------------------
block replica-create
run "$CREATE --query DBInstance.DBInstanceStatus"
run "aws rds create-db-instance-read-replica --db-instance-identifier quitanda-orders-reports --source-db-instance-identifier quitanda-orders --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier,Endpoint.Address]' --output text"
run "aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'"
block replica-lag
run "aws rds describe-db-instances --db-instance-identifier quitanda-orders-reports --query 'DBInstances[0].StatusInfos'"
run "aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name ReplicaLag --dimensions Name=DBInstanceIdentifier,Value=quitanda-orders-reports --start-time 2026-10-16T00:00:00Z --end-time 2026-10-17T00:00:00Z --period 60 --statistics Maximum"
block replica-promote
run "aws rds promote-read-replica --db-instance-identifier quitanda-orders-reports --query 'DBInstance.[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier]' --output text"
run "aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'"
block replica-region
run "aws rds create-db-instance-read-replica --db-instance-identifier quitanda-orders-dr --source-db-instance-identifier arn:aws:rds:sa-east-1:123456789012:db:quitanda-orders --region us-east-1 --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceArn,AvailabilityZone]' --output text"
block price-transfer
run 'python3 prices.py transfer'
block replica-nobackup
run "aws rds create-db-instance --db-instance-identifier quitanda-scratch --engine postgres --engine-version 16 --db-instance-class db.t4g.micro --allocated-storage 20 --master-username quitanda --manage-master-user-password --backup-retention-period 0 --query DBInstance.BackupRetentionPeriod"
run "aws rds create-db-instance-read-replica --db-instance-identifier quitanda-scratch-copy --source-db-instance-identifier quitanda-scratch --query DBInstance.DBInstanceStatus"
moto_stop; moto_start

# ---- point-in-time ------------------------------------------------------------
block pitr-window
run "$CREATE --query 'DBInstance.[BackupRetentionPeriod,PreferredBackupWindow]' --output text"
run "aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].[InstanceCreateTime,LatestRestorableTime]' --output text"
block pitr-restore
run "aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier quitanda-orders --target-db-instance-identifier quitanda-orders-restored --use-latest-restorable-time --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,Endpoint.Address]' --output text"
run "aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,Endpoint.Address]' --output text"
block pitr-lax
run "aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier quitanda-orders --target-db-instance-identifier quitanda-orders-october --restore-time 2026-10-01T09:00:00-03:00 --query DBInstance.DBInstanceStatus"
run "aws rds modify-db-instance --db-instance-identifier quitanda-orders --backup-retention-period 36 --apply-immediately --query DBInstance.BackupRetentionPeriod"
moto_stop; moto_start

# ---- snapshots ----------------------------------------------------------------
block snap-create
run "$CREATE --query DBInstance.DBInstanceStatus"
run "aws rds describe-db-snapshots --db-instance-identifier quitanda-orders --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotType]' --output text"
run "aws rds create-db-snapshot --db-instance-identifier quitanda-orders --db-snapshot-identifier quitanda-orders-before-v2 --query 'DBSnapshot.[DBSnapshotIdentifier,SnapshotType,Status]' --output text"
block snap-delete
run "aws rds delete-db-instance --db-instance-identifier quitanda-orders --skip-final-snapshot --query DBInstance.DBInstanceStatus"
run "aws rds describe-db-snapshots --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotType]' --output text"
block snap-restore
run "aws rds restore-db-instance-from-db-snapshot --db-instance-identifier quitanda-orders-v1 --db-snapshot-identifier quitanda-orders-before-v2 --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,Endpoint.Address]' --output text"
block snap-noflag
run "aws rds delete-db-instance --db-instance-identifier quitanda-orders-v1 --query DBInstance.DBInstanceStatus"
