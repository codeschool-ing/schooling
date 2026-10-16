#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of aws-data (RDS), as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal": moto empty on 4567, the four lines exported. moto is restarted
# between sections, so each one starts from an empty AWS, as a student who
# stops for the day does.
#
# The network of "an-instance" is the first ```sh fence of that section, run
# as it stands and sourced, so the variables it sets are the ones the commands
# after it use.
#
# moto's own terminal is not shown in any transcript. Where the prose quotes
# what it printed (the line naming an action it has not implemented), the
# block `moto-log` below is that line, read from moto's log.
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

# ---- the-engines -------------------------------------------------------------
block engines-versions
run 'aws rds describe-db-engine-versions --engine postgres'
block moto-log
grep -m1 '^NotImplementedError' ~/.moto.log
block engines-defaults
run 'for e in postgres mysql oracle-se2 sqlserver-se; do aws rds create-db-instance --db-instance-identifier try-$e --engine $e --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query "DBInstance.[Engine,EngineVersion,Endpoint.Port,LicenseModel]" --output text; done'
block engines-named
run "aws rds create-db-instance --db-instance-identifier try-mariadb --engine mariadb --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.EngineVersion'"
run "aws rds create-db-instance --db-instance-identifier try-mariadb --engine mariadb --engine-version 11.4 --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.[Engine,EngineVersion,Endpoint.Port,LicenseModel]' --output text"
run "aws rds create-db-instance --db-instance-identifier try-oracle-ee --engine oracle-ee --license-model bring-your-own-license --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.[Engine,LicenseModel]' --output text"
run "aws rds create-db-instance --db-instance-identifier try-db2 --engine db2-se --license-model bring-your-own-license --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password"
moto_stop; moto_start

# ---- an-instance -------------------------------------------------------------
. <(fence "$LESSONS/le-nb1pn64k/an-instance.md" 1) || exit 1
export VPC APP_SG DB_SG SUBNET_A SUBNET_B
block instance-groups
run 'aws rds create-db-subnet-group --db-subnet-group-name quitanda-db --db-subnet-group-description "Quitanda databases, two zones" --subnet-ids $SUBNET_A $SUBNET_B --query "DBSubnetGroup.Subnets[].[SubnetIdentifier,SubnetAvailabilityZone.Name]" --output text'
run 'aws rds create-db-parameter-group --db-parameter-group-name quitanda-pg16 --db-parameter-group-family postgres16 --description "Quitanda orders, PostgreSQL 16" --query DBParameterGroup.DBParameterGroupArn'
block instance-create
run 'aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --db-subnet-group-name quitanda-db --vpc-security-group-ids $DB_SG --db-parameter-group-name quitanda-pg16 --backup-retention-period 7 --no-publicly-accessible --query "DBInstance.[DBInstanceStatus,Endpoint.Address,Endpoint.Port,AvailabilityZone,StorageType]" --output text'
block instance-nothing
run 'date -u +%Y-%m-%dT%H:%M:%S'
run 'aws rds describe-db-instances --db-instance-identifier quitanda-orders --query "DBInstances[0].[DBInstanceStatus,InstanceCreateTime,MasterUserSecret.SecretStatus]" --output text'
run 'aws rds create-db-instance --db-instance-identifier quitanda-banana --engine postgres --engine-version 16 --db-instance-class db.banana.huge --allocated-storage 100 --master-username quitanda --manage-master-user-password --query "DBInstance.[DBInstanceClass,DBInstanceStatus]" --output text'

# ---- parameter-groups (same moto: the instance above is still there) ----------
block params-modify
run 'aws rds modify-db-parameter-group --db-parameter-group-name quitanda-pg16 --parameters "ParameterName=log_min_duration_statement,ParameterValue=500,ApplyMethod=immediate" "ParameterName=max_connections,ParameterValue=400,ApplyMethod=pending-reboot"'
run 'aws rds describe-db-parameters --db-parameter-group-name quitanda-pg16 --source user --query "Parameters[].[ParameterName,ParameterValue,ApplyMethod]" --output text'
block params-status
run 'aws rds describe-db-instances --db-instance-identifier quitanda-orders --query "DBInstances[0].DBParameterGroups"'
run 'aws rds reboot-db-instance --db-instance-identifier quitanda-orders --query DBInstance.DBInstanceStatus'
block params-lax
run 'aws rds modify-db-parameter-group --db-parameter-group-name quitanda-pg16 --parameters "ParameterName=no_such_setting,ParameterValue=banana,ApplyMethod=immediate"'
run 'aws rds describe-db-parameters --db-parameter-group-name quitanda-pg16 --query "length(Parameters)"'
run 'aws rds modify-db-parameter-group --db-parameter-group-name default.postgres16 --parameters "ParameterName=work_mem,ParameterValue=65536,ApplyMethod=immediate"'

# ---- what-it-costs -----------------------------------------------------------
block price-rds
run 'python3 prices.py rds'
