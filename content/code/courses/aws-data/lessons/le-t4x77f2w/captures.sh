#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of aws-data (MSK and Kafka), as a
# script that produces them. Every transcript in the lesson was copied from its
# output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# TWO DIFFERENT THINGS ANSWER HERE. The MSK commands go to moto, empty when
# this starts, which records a cluster and runs no broker. The Kafka commands
# go to a real Apache Kafka 4.4.0 broker, one node in KRaft mode, started from
# the release the lesson tells the student to download.
#
# STAGED, and why:
#   - the capture has no network, so the release was downloaded beforehand
#     from https://archive.apache.org/dist/kafka/4.4.0/kafka_2.13-4.4.0.tgz
#     (SHA-512 checked against the .sha512 file published beside it) and is
#     copied into ~/aws here, where the lesson's curl would have put it.
#     KAFKA_TGZ names the copy.
#   - Java is OpenJDK 21 from Ubuntu 24.04, already installed on the recording
#     machine, which is what the lesson's apt-get line installs. The recording
#     machine sets JAVA_TOOL_OPTIONS for its proxy, and Java announces that on
#     every start, so it is unset here; a student's machine has none.
#   - the broker runs in the student's third terminal, in the foreground. Here
#     it runs in the background with its output in a file, from the same
#     directory and with the same command, and is stopped at the end with the
#     script Kafka ships for that. /tmp/kraft-combined-logs, the log directory
#     of the shipped configuration, is emptied first, as on a fresh machine.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
unset JAVA_TOOL_OPTIONS
cd ~/aws || exit 1
cp "${KAFKA_TGZ:-/tmp/claude-0/w/F/dl/kafka_2.13-4.4.0.tgz}" . || exit 1
rm -rf /tmp/kraft-combined-logs

block java
run 'java -version'
run 'du -h kafka_2.13-4.4.0.tgz'
run 'tar -xzf kafka_2.13-4.4.0.tgz && ls kafka_2.13-4.4.0'

cd kafka_2.13-4.4.0 || exit 1
PROMPT_DIR='~/aws/kafka_2.13-4.4.0'
B='--bootstrap-server localhost:9092'
block format
run 'KAFKA_CLUSTER_ID="$(bin/kafka-storage.sh random-uuid)" && bin/kafka-storage.sh format --standalone -t $KAFKA_CLUSTER_ID -c config/server.properties'

( bin/kafka-server-start.sh config/server.properties > "$HOME/.kafka.log" 2>&1 & )
for _ in $(seq 120); do (echo > /dev/tcp/127.0.0.1/9092) 2>/dev/null && break; sleep 0.5; done
sleep 3

block topic
run "bin/kafka-topics.sh $B --create --topic orders --partitions 3 --replication-factor 1"
run "bin/kafka-topics.sh $B --describe --topic orders"

block produce
run "printf 'c-17:o-101 placed\nc-02:o-102 placed\nc-17:o-101 packed\nc-05:o-103 placed\n' | bin/kafka-console-producer.sh $B --topic orders --reader-property parse.key=true --reader-property key.separator=:"
run "bin/kafka-console-consumer.sh $B --topic orders --group fraud --from-beginning --max-messages 4 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true"
run "bin/kafka-consumer-groups.sh $B --describe --group fraud"

block lag
run "printf 'c-17:o-101 delivered\nc-02:o-102 packed\nc-05:o-103 cancelled\n' | bin/kafka-console-producer.sh $B --topic orders --reader-property parse.key=true --reader-property key.separator=:"
run "bin/kafka-consumer-groups.sh $B --describe --group fraud"
run "bin/kafka-console-consumer.sh $B --topic orders --group fraud --max-messages 3 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true"

block replay
run "bin/kafka-consumer-groups.sh $B --group fraud --topic orders --reset-offsets --to-earliest --execute"
run "bin/kafka-console-consumer.sh $B --topic orders --group fraud --max-messages 7 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true"

block retention
run "bin/kafka-configs.sh $B --entity-type topics --entity-name orders --alter --add-config retention.ms=604800000,retention.bytes=10737418240"
run "bin/kafka-configs.sh $B --entity-type topics --entity-name orders --describe"
run 'ls /tmp/kraft-combined-logs/orders-1/'
run "bin/kafka-get-offsets.sh $B --topic orders"

block rf3
run "bin/kafka-topics.sh $B --create --topic orders-rf3 --partitions 3 --replication-factor 3"

bin/kafka-server-stop.sh > /dev/null 2>&1
for _ in $(seq 60); do (echo > /dev/tcp/127.0.0.1/9092) 2>/dev/null || break; sleep 0.5; done

cd ~/aws || exit 1
PROMPT_DIR='~/aws'
block msk
run 'aws kafka create-cluster --cluster-name quitanda-events --kafka-version 3.9.x --number-of-broker-nodes 3 --broker-node-group-info "InstanceType=kafka.m7g.large,ClientSubnets=subnet-a,subnet-b,subnet-c,StorageInfo={EbsStorageInfo={VolumeSize=200}}"'
ARN=$(aws kafka list-clusters --query 'ClusterInfoList[0].ClusterArn' --output text)
run "aws kafka describe-cluster --cluster-arn $ARN --query 'ClusterInfo.[State,NumberOfBrokerNodes,BrokerNodeGroupInfo.InstanceType,ZookeeperConnectString]'"
run "aws kafka get-bootstrap-brokers --cluster-arn $ARN"
run 'aws kafka create-cluster-v2 --cluster-name quitanda-events-sls --serverless "VpcConfigs=[{SubnetIds=[subnet-a,subnet-b,subnet-c]}]"'
run "aws kafka list-clusters-v2 --query 'ClusterInfoList[].[ClusterName,ClusterType,State]' --output text"
run 'aws kafkaconnect list-connectors'

block prices
run 'python3 prices.py kinesis msk'
run 'python3 prices.py transfer | grep zones'
