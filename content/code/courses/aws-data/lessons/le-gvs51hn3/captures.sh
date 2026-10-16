#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of aws-data (Redshift), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# Redshift itself is not run anywhere in this lesson. moto records clusters,
# accepts SQL through the Data API and runs none of it; Redshift Serverless is
# not implemented by moto at all. The two programs are models of the arithmetic
# of distribution and of zone maps, read out of the lesson's own .md files, and
# the DDL file is read out of distribution.md the same way.
#
# STAGED: nothing.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$LESSONS/le-gvs51hn3"

block mpp-moto
run 'aws redshift create-cluster --cluster-identifier quitanda-dw --node-type ra3.xlplus --number-of-nodes 2 --master-username quitanda_admin --master-user-password Lab-only-0 --db-name quitanda --query "Cluster.[ClusterStatus,NodeType,NumberOfNodes]" --output text'
run 'aws redshift describe-clusters --query "Clusters[].[ClusterIdentifier,ClusterStatus,Endpoint.Address]" --output text'
run 'aws redshift create-cluster --cluster-identifier quitanda-typo --node-type ra3.xlpluss --number-of-nodes 2 --master-username quitanda_admin --master-user-password Lab-only-0 --query Cluster.ClusterStatus --output text'

block mpp-sql
OUT=$(run 'aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql "CREATE TABLE stores (store_id SMALLINT NOT NULL, name VARCHAR(64) NOT NULL) DISTSTYLE ALL" --query Id --output text')
printf '%s\n' "$OUT"; ID=$(printf '%s\n' "$OUT" | tail -1)
run "sleep 5; aws redshift-data describe-statement --id $ID --query '[Status,HasResultSet,QueryString]' --output text"
OUT=$(run 'aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql "SELECT dt, count(*) FROM orders GROUP BY dt" --query Id --output text')
printf '%s\n' "$OUT"; ID=$(printf '%s\n' "$OUT" | tail -1)
run "aws redshift-data get-statement-result --id $ID --query 'Records[*].[[0].longValue,[1].stringValue,[2].stringValue]' --output text"

file_fence "$L/distribution.md" orders.sql > orders.sql || exit 1
block ddl-moto
OUT=$(run 'aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql file://orders.sql --query Id --output text')
printf '%s\n' "$OUT"; ID=$(printf '%s\n' "$OUT" | tail -1)
run "aws redshift-data describe-statement --id $ID --query '[Status,HasResultSet]' --output text"

example "$L/distribution.md" slices.py slices.py || exit 1
block slices
run 'python3 slices.py'

example "$L/sort-keys.md" zonemaps.py zonemaps.py || exit 1
block zonemaps
run 'python3 zonemaps.py'

block serverless-moto
run 'aws redshift-serverless create-namespace --namespace-name quitanda'
run 'aws redshift-serverless create-workgroup --workgroup-name quitanda-adhoc --namespace-name quitanda --base-capacity 8'

block prices-redshift
run 'python3 prices.py redshift'

block pause
run 'aws redshift pause-cluster --cluster-identifier quitanda-dw --query Cluster.ClusterStatus --output text'
run 'aws redshift describe-clusters --cluster-identifier quitanda-dw --query "Clusters[0].[ClusterStatus,NumberOfNodes]" --output text'
run 'aws redshift resume-cluster --cluster-identifier quitanda-dw --query Cluster.ClusterStatus --output text'
