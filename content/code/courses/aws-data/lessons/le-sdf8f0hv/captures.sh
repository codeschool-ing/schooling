#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of aws-data (Aurora), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal": moto empty on 4567, the four lines exported. moto is restarted
# before the Serverless section, so it starts from an empty AWS.
#
# NOTHING HERE HAS A STORAGE LAYER. moto keeps a record per cluster and per
# instance; the six copies, the quorum, the shared volume and the replica lag
# are taught from AWS's published design and documentation, and the lesson says
# so where it does. Where moto refuses a request with an HTML 500, the line
# moto's own terminal printed is read from its log in a block of its own.
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

# ---- a-cluster ----------------------------------------------------------------
block cluster-create
run "aws rds create-db-cluster --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query 'DBCluster.[Status,Endpoint,ReaderEndpoint]'"
run "aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].Status'"
block cluster-instances
run "aws rds create-db-instance --db-instance-identifier quitanda-aurora-1 --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --availability-zone sa-east-1a --query 'DBInstance.[DBInstanceStatus,AvailabilityZone,Endpoint.Address]' --output text"
run "aws rds create-db-instance --db-instance-identifier quitanda-aurora-2 --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --availability-zone sa-east-1b --query 'DBInstance.[DBInstanceStatus,AvailabilityZone,Endpoint.Address]' --output text"
run "aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter,PromotionTier]' --output text"
block cluster-storage
run "aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].[StorageType,AllocatedStorage]' --output text"
run "aws rds describe-db-instances --db-instance-identifier quitanda-aurora-1 --query 'DBInstances[0].[StorageType,AllocatedStorage]' --output text"
block cluster-iopt
run "aws rds create-db-cluster --db-cluster-identifier quitanda-aurora-io --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --storage-type aurora-iopt1"
block moto-log-iopt
grep -m1 '^KeyError' ~/.moto.log

# ---- replicas-and-endpoints -----------------------------------------------------
block failover
run "aws rds failover-db-cluster --db-cluster-identifier quitanda-aurora --target-db-instance-identifier quitanda-aurora-2 --query 'DBCluster.DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter]' --output text"
block custom-endpoint
run "aws rds create-db-cluster-endpoint --db-cluster-identifier quitanda-aurora --db-cluster-endpoint-identifier quitanda-reports --endpoint-type READER --static-members quitanda-aurora-1"
block moto-log-endpoint
grep '^NotImplementedError' ~/.moto.log | tail -1
block fifteen
run 'for i in $(seq 3 17); do aws rds create-db-instance --db-instance-identifier quitanda-aurora-$i --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --query DBInstance.DBInstanceStatus --output text; done | sort | uniq -c'
run "aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'length(DBClusters[0].DBClusterMembers)'"
moto_stop; moto_start

# ---- serverless-v2 ------------------------------------------------------------
block sls-create
run "aws rds create-db-cluster --db-cluster-identifier quitanda-dev --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --serverless-v2-scaling-configuration MinCapacity=0,MaxCapacity=8,SecondsUntilAutoPause=900 --query 'DBCluster.ServerlessV2ScalingConfiguration'"
run "aws rds create-db-instance --db-instance-identifier quitanda-dev-1 --db-cluster-identifier quitanda-dev --engine aurora-postgresql --db-instance-class db.serverless --query 'DBInstance.[DBInstanceClass,DBInstanceStatus]' --output text"
block sls-lax
run "aws rds create-db-cluster --db-cluster-identifier quitanda-backwards --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --serverless-v2-scaling-configuration MinCapacity=300,MaxCapacity=2 --query 'DBCluster.ServerlessV2ScalingConfiguration'"

# ---- prices ---------------------------------------------------------------------
block price-aurora
run 'python3 prices.py aurora'
