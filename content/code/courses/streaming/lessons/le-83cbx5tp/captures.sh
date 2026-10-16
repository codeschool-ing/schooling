#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-83cbx5tp.out 2>&1
#
# STAGED, not typed, and said here: each part starts from a fresh cluster
# (`lab reset 1`, and `lab reset 3` for what-to-alert-on), as if the student
# had run `./cluster.sh stop`, `new` and `start`. The "second shell" programs
# are started in the background and their screens printed when they stop;
# the waits between two commands of the lag section are sleeps here and
# the student's own pace there. The datetime typed in replay is the moment
# fifteen seconds after tills.py started in consumer-lag, computed by this
# script; the student types a moment of their own.
# NOT RUN: a real failure domain (the three nodes share one machine), and an
# alert rule in any monitoring system; the section describes them.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1

# consumer-lag ---------------------------------------------------------------
block topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
block consumer-start
shown 'python slow_consumer.py --delay 0.1'
term2 slow 'python slow_consumer.py --delay 0.1' 4
T0=$(date +%s)
block tills-start
shown 'python tills.py --count 600 --rate 20'
term2 tills 'python tills.py --count 600 --rate 20' 10
block lag-10
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock'
sleep 9
block lag-20
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock'
block lagsec
vm 'python lag_seconds.py stock'
block tills-done
wait2 tills
block lag-30
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock'
sleep 35
block lag-end
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock'
block lagsec-end
vm 'python lag_seconds.py stock'

# replay ---------------------------------------------------------------------
block replay-refused
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-earliest --execute'
block slow-screen
stop2 slow
block replay-dry
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-earliest --dry-run'
AT=$(date -d "@$((T0 + 15))" +%Y-%m-%dT%H:%M:%S.000%:z)
block replay-datetime
vm "kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-datetime $AT --execute"
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock'

# backpressure ---------------------------------------------------------------
block audit-good
shown 'python slow_consumer.py --group audit --delay 0.5 --max-poll 6000'
term2 good 'python slow_consumer.py --group audit --delay 0.5 --max-poll 6000' 6
block audit-bad
shown 'python slow_consumer.py --group audit --delay 8 --max-poll 6000'
term2 bad 'python slow_consumer.py --group audit --delay 8 --max-poll 6000' 30
block audit-bad-screen
stop2 bad
block audit-good-screen
stop2 good

# poison-messages ------------------------------------------------------------
block count-first
vm 'python sturdy_consumer.py'
block poison
vm "echo 'recife|bk-03;1;2990' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property key.separator='|'"
vm 'python tills.py --count 30 --rate 0 --seed 5'
block crash-1
vm 'python sturdy_consumer.py'
block stuck
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count'
block crash-2
vm 'python sturdy_consumer.py'
block stuck-2
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count'
block dlq
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales.dlq --partitions 1'
vm 'python sturdy_consumer.py --dead-letter sales.dlq'
block dlq-read
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales.dlq --from-beginning --max-messages 1 --formatter-property print.headers=true'

# reprocessing ---------------------------------------------------------------
block v2
vm 'python sturdy_consumer.py --group stock-v2 --dead-letter sales.dlq'
block groups
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list'
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-v2'
block delete-v1
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group stock-count'

# what-to-alert-on -----------------------------------------------------------
lab reset 3
block urp-none
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3 --replication-factor 3'
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions'
block urp-kill
vm './cluster.sh kill 3'
sleep 15
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions'
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --unavailable-partitions'
block urp-back
vm './cluster.sh start 3'
sleep 10
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions'
block disk
vm 'df -h ~/kafka-data'
vm 'du -sh ~/kafka-data/node*/log'
lab reset 1 >/dev/null
