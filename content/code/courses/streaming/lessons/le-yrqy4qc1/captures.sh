#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-yrqy4qc1.out
#
# STAGED, not typed, and said here: the lab is reset to a running one-node
# cluster first, so the `stop`, `new 1` and `start` the lesson shows run on
# a cluster that exists. Two waits are the script's rather than the
# student's: after retention.bytes is set, it polls the earliest offset
# until the broker's retention check has run (that check runs every five
# minutes, and here it ran within the first one), and it waits 65 seconds
# before listing the directory again, so the `.deleted` files have gone.
# For compaction it waits six seconds before the last message, so the
# segment is old enough to roll, and then polls until the cleaner has run.
# Nothing in the lesson was left unrun.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1

# topics-and-partitions
block fresh
vm './cluster.sh stop'
vm './cluster.sh new 1'
vm './cluster.sh start'
block create
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic sales'

# keys-to-partitions
block keys-default
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic shops --partitions 3'
vm 'python keys.py shops recife=py olinda=py caruaru=py natal=py joao-pessoa=py'
block keys-java
vm 'printf "recife:java\nolinda:java\ncaruaru:java\nnatal:java\njoao-pessoa:java\n" | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic shops --reader-property parse.key=true --reader-property key.separator=:'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic shops --from-beginning --max-messages 10 --formatter-property print.partition=true --formatter-property print.key=true'
block keys-murmur
vm 'python keys.py --partitioner murmur2_random shops recife=m2 olinda=m2 caruaru=m2 natal=m2 joao-pessoa=m2'

# offsets
block tills
vm 'python tills.py --count 1000 --rate 0'
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic sales'
block earliest
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic sales --time earliest'
block from-offset
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --partition 1 --offset 5 --max-messages 2 --formatter-property print.offset=true'

# on-disk
block ls-partition
vm 'ls -l ~/kafka-data/node1/log/sales-1'
block dump
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-1/00000000000000000000.log --print-data-log | head -5'
block dump-index
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-1/00000000000000000000.index'

# retention
block configs
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --topic sales | grep -E "retention.(ms|bytes)|segment.(ms|bytes)|cleanup"'
block old-sales
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic old-sales --partitions 1 --config segment.bytes=1048576'
vm 'python tills.py --topic old-sales --count 20000 --rate 0'
vm 'ls ~/kafka-data/node1/log/old-sales-0/*.log'
block retention-set
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --alter --topic old-sales --add-config retention.bytes=1048576'
for i in $(seq 1 80); do
  e=$(run 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic old-sales --time earliest' | cut -d: -f3)
  [ "$e" != "0" ] && break; sleep 5
done
block retention-after
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic old-sales --time earliest'
vm 'ls ~/kafka-data/node1/log/old-sales-0/*.log*'
sleep 65
block retention-later
vm 'ls ~/kafka-data/node1/log/old-sales-0/*.log*'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic old-sales --from-beginning --max-messages 1 --formatter-property print.offset=true'

# compaction
block stock
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock --partitions 1 --config cleanup.policy=compact --config segment.ms=5000 --config min.cleanable.dirty.ratio=0.01'
vm 'python keys.py stock bk-01=4 bk-02=7 bk-03=2 bk-01=3 bk-02=6 bk-01=2 bk-03=-'
sleep 6
block stock-roll
vm 'python keys.py stock bk-04=9'
for i in $(seq 1 30); do
  n=$(run 'kafka-dump-log.sh --files ~/kafka-data/node1/log/stock-0/00000000000000000000.log' | grep -c '^| offset\|^baseOffset')
  [ -n "$(run 'ls ~/kafka-data/node1/log/stock-0/' | grep deleted)" ] && break; sleep 5
done
block stock-after
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock --from-beginning --max-messages 4 --formatter-property print.offset=true --formatter-property print.key=true'

# choosing-partitions
block more-partitions
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 4'
vm 'python keys.py --partitioner murmur2_random shops recife=4p olinda=4p caruaru=4p natal=4p joao-pessoa=4p'
block fewer
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 2'
