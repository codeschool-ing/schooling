#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-bg6rxmx7.out 2>&1
#
# STAGED, not typed, and said here: the cluster is fresh (`lab reset 1`), as
# if the student had run `./cluster.sh stop`, `new 1` and `start`. The
# minute between the two `ps` lines of the-quiet-hours is a sleep here.
# NOT RUN: tiered storage (it needs a remote storage plugin and an object
# store, neither of which Kafka ships), a managed service of any kind, and a
# real bill; producer-side compression (`compression.type` on the producer)
# is described and not measured, the topic-level setting is what was run.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1

# measuring-a-message
block bytes-fill
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic bytes --partitions 1'
vm 'python tills.py --topic bytes --count 100000 --rate 0'
block one-sale
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic bytes --from-beginning --max-messages 1 2>/dev/null | wc -c'
block logdirs
vm 'kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list bytes'
block per-sale
vm "kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list bytes | grep '^{' | jq '.brokers[0].logDirs[0].partitions[0].size / 100000'"
block ls
vm 'ls -l ~/kafka-data/node1/log/bytes-0'

# compression
block comp-topics
vm 'for c in none gzip lz4 zstd; do kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-$c --partitions 1 --config compression.type=$c; done'
block comp-fill
vm 'for c in none gzip lz4 zstd; do python tills.py --topic sales-$c --count 100000 --rate 0; done'
block comp-sizes
vm "kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list sales-none,sales-gzip,sales-lz4,sales-zstd | grep '^{' | jq -r '.brokers[0].logDirs[0].partitions[] | \"\(.partition)  \(.size)  \(.size / 100000 * 10 | round / 10)\"' | sort -k2 -n -r"

# retention-arithmetic
block bill-ponto
vm 'python bill.py 20000 38.5 7 3'
block bill-year
vm 'python bill.py 20000 38.5 365 3'
block bill-clicks
vm 'python bill.py 50000000 400 7 3'
block retention
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name sales-zstd --alter --add-config retention.ms=604800000'
vm 'kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name sales-zstd --describe'

# the-quiet-hours
sleep 20
block idle
vm "ps -o rss,etime,time -p \$(pgrep -f '^[^ ]*java .*node1')"
sleep 60
block idle-2
vm "ps -o rss,etime,time -p \$(pgrep -f '^[^ ]*java .*node1')"
vm 'du -sh ~/kafka-data'
lab reset 1 >/dev/null
