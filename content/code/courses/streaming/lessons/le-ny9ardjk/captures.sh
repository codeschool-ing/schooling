#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-ny9ardjk.out 2>&1
#
# STAGED, not typed, and said here: the lab starts from a running one-node
# cluster, which the first block stops and replaces with three. Which node
# leads which partition is decided by Kafka at creation time, so this script
# reads the leader of the partition `recife` lands in from the describe output
# and kills that node; the lesson tells the student to read the same line.
# The `sleep`s are typed in the lesson too: they are the time Kafka needs to
# notice. Nothing here was NOT run, except that every node shares one machine,
# so no real failure domain (a rack, a zone) is ever lost.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1 >/dev/null
DESCRIBE='kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic sales'
leader_of() { run "$DESCRIBE" | awk -v p="$1" '$3 == "Partition:" && $4 == p {print $6}'; }

block new3
vm './cluster.sh stop'
vm './cluster.sh new 3'
vm './cluster.sh start'
block create
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3 --replication-factor 3 --config min.insync.replicas=2'
vm "$DESCRIBE"
block dirs
vm 'ls ~/kafka-data/node1/log ~/kafka-data/node2/log ~/kafka-data/node3/log | grep sales'

block copies
vm 'python tills.py --count 300 --rate 0'
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic sales'
vm 'wc -c ~/kafka-data/node*/log/sales-1/*.log'

block lagtime
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --broker 1 | grep replica.lag.time.max.ms'
block pause
vm 'kill -STOP $(pgrep -f "^[^ ]*java .*node3/")'
vm "sleep 40; $DESCRIBE"
block resume
vm 'kill -CONT $(pgrep -f "^[^ ]*java .*node3/")'
vm "sleep 10; $DESCRIBE"

block acks-ok
vm 'python acks.py --acks 0'
vm 'python acks.py --acks 1'
vm 'python acks.py --acks all'
block one-down
vm './cluster.sh kill 3'
vm "sleep 15; $DESCRIBE"
vm 'python acks.py --acks all'
block min3
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=3'
vm 'python acks.py --acks all'
vm 'grep -h -m1 NotEnoughReplicasException ~/kafka-data/node*/logs/server.log'
vm 'python acks.py --acks 1'
block min2
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=2'
vm './cluster.sh start 3'

# a-node-dies
sleep 10
block before-kill
vm "$DESCRIBE"
P=$(run 'python acks.py --acks all --count 1' | awk '/^partition/ {print $2}' | tr -d :)
L=$(leader_of "$P")
echo "# (author) recife -> partition $P, leader $L" >&2
block producing
shown 'python acks.py --acks all --count 100 --rate 5'
term2 prod 'python acks.py --acks all --count 100 --rate 5' 6
vm "./cluster.sh kill $L"
block produced
wait2 prod
block after-kill
vm "$DESCRIBE"
block back
vm "./cluster.sh start $L"
vm "sleep 10; $DESCRIBE"
block preferred
vm 'kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type preferred --all-topic-partitions'
vm "$DESCRIBE"

# the-controllers
block quorum
vm 'kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status'
block two-down
vm './cluster.sh kill 2'
vm './cluster.sh kill 3'
vm 'timeout 60 kafka-topics.sh --bootstrap-server localhost:9092 --create --topic returns --partitions 3 2>/dev/null'
vm 'timeout 30 kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status 2>/dev/null'
block quorum-back
vm './cluster.sh start'
vm 'kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status | grep -E "LeaderId|HighWatermark"'

# unclean-election
sleep 5
block till-log
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic till-log --replica-assignment 2:3 --config min.insync.replicas=1'
vm 'python acks.py --topic till-log'
vm './cluster.sh kill 3'
vm 'sleep 15; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log'
vm 'python acks.py --topic till-log'
block offline
vm './cluster.sh kill 2'
vm './cluster.sh start 3'
vm 'sleep 15; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log'
vm 'python acks.py --topic till-log --count 1'
block unclean
vm 'kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type unclean --topic till-log --partition 0'
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log'
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic till-log'
block node2-back
vm './cluster.sh start 2'
vm 'sleep 10; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log'
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic till-log'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic till-log --from-beginning --timeout-ms 5000 2>/dev/null | wc -l'
