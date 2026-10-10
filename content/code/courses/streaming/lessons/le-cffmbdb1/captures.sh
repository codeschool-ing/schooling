#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-cffmbdb1.out
#
# STAGED, not typed, and said here: the lab is reset to a running one-node
# cluster first. Each "second shell" is a background process whose screen
# is printed when it is stopped; the pauses between starting them (eight
# seconds, so each has joined its group) are the script's. Stopping a
# consumer is Ctrl+C, sent as SIGINT; the crash in committing-offsets is
# `kill -9`, sent as SIGKILL to the program. The producer that runs with the
# cluster stopped has its stderr thrown away on the command line, which the
# lesson shows and explains. Nothing in the lesson was left unrun.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1

# a-producer
block topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
vm 'python producer.py'
block batching
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger0 --partitions 1'
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger100 --partitions 1'
vm 'python producer.py --topic linger0 --count 200 --rate 200 --linger-ms 0'
vm 'python producer.py --topic linger100 --count 200 --rate 200 --linger-ms 100'
block batches
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/linger0-0/00000000000000000000.log | grep -c baseOffset'
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/linger100-0/00000000000000000000.log | grep -c baseOffset'
block down
vm './cluster.sh stop'
vm 'python producer.py --count 5 --timeout-ms 5000 2>/dev/null'
vm './cluster.sh start'

# a-consumer
block c1
term2 c1 'python consumer.py c1' 10
stop2 c1
block c1-describe
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock'

# consumer-groups and more-consumers-than-partitions
term2 a 'python consumer.py a --group shelf' 8
term2 b 'python consumer.py b --group shelf' 8
block two
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group shelf'
term2 c 'python consumer.py c --group shelf' 8
term2 d 'python consumer.py d --group shelf' 8
block four
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group shelf --members'
block more
vm 'python producer.py'
sleep 3
block term-a
stop2 d >/tmp/term-d; stop2 c >/tmp/term-c; stop2 b >/tmp/term-b; stop2 a
block term-b
cat /tmp/term-b
block term-c
cat /tmp/term-c
block term-d
cat /tmp/term-d
rm -f /tmp/term-[bcd]

# rebalancing, on an empty topic so that only the assignments print
run 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic quiet --partitions 3' >/dev/null
for s in eager:range coop:cooperative-sticky; do
  g=${s%%:*}; st=${s##*:}
  block "reb-$g-a"
  term2 a "python consumer.py a --group $g --topic quiet --strategy $st" 8
  term2 b "python consumer.py b --group $g --topic quiet --strategy $st" 8
  stop2 b > /tmp/term-b; sleep 5
  stop2 a
  block "reb-$g-b"
  cat /tmp/term-b
done
block reb-848-a
term2 a 'python consumer.py a --group new --topic quiet --protocol consumer' 8
term2 b 'python consumer.py b --group new --topic quiet --protocol consumer' 8
block reb-848-describe
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group new --members'
stop2 b > /tmp/term-b; sleep 5
block reb-848-term-a
stop2 a
block reb-848-b
cat /tmp/term-b
rm -f /tmp/term-b

# committing-offsets
block crash-auto
term2 x 'python consumer.py x --group auto' 4
stop2 x KILL
block crash-auto-describe
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group auto'
block crash-manual
term2 y 'python consumer.py y --group manual --manual' 4
stop2 y KILL
block crash-manual-describe
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group manual'
block offsets-topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic __consumer_offsets | head -1'

# reading-from-a-point
block reset-dry
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales --reset-offsets --to-earliest --dry-run'
block reset-exec
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales:1 --reset-offsets --to-offset 3 --execute'
block reset-read
term2 c1 'python consumer.py c1' 10
stop2 c1
block rewind
T=$(run 'date "+%F %T"')
shown 'date "+%F %T"'; echo "$T"
sleep 2
vm 'python producer.py --count 5'
vm "python rewind.py sales '$T'"
