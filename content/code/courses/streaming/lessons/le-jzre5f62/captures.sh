#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of streaming (event time against
# processing time), as a script that produces them. Its output is not
# committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-jzre5f62.out
#
# STAGED, not typed, and said here: the lab starts from a fresh one-node
# cluster (`lab.sh reset 1`), so the topics this lesson makes are the only
# ones besides Kafka's own. late_tills.py cannot wait four hours for Natal's
# till to come back, so it stamps each record with the moment it WOULD have
# been sent; the lesson says so. The `date` command that decodes a timestamp
# is built from the number the consumer printed just above it.
#
# NOT RUN: timedatectl and chrony (the container has no systemd and no clock
# of its own to set); the lesson marks them as not run.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1 >/dev/null 2>&1
K='--bootstrap-server localhost:9092'

# three-clocks
block clocks-topics
vm "kafka-topics.sh $K --create --topic clocks --partitions 1"
vm "kafka-topics.sh $K --create --topic appended --partitions 1 --config message.timestamp.type=LogAppendTime"
block clocks-send
vm 'python tills.py --count 2 --topic clocks'
vm 'python tills.py --count 2 --topic appended'
block clocks-read
out=$(vm "kafka-console-consumer.sh $K --topic clocks --from-beginning --max-messages 2 --formatter-property print.timestamp=true")
printf '%s\n' "$out"
ts=$(printf '%s\n' "$out" | grep -o 'CreateTime:[0-9]*' | head -1 | cut -d: -f2)
vm "date -d @${ts:0:10} '+%F %T %z'"
block appended-read
vm "kafka-console-consumer.sh $K --topic appended --from-beginning --max-messages 2 --formatter-property print.timestamp=true"

# skew
block late-topic
vm "kafka-topics.sh $K --create --topic late --partitions 1 --config retention.ms=-1"
vm 'python late_tills.py'
block late-burst
C="kafka-console-consumer.sh $K --topic late --from-beginning --max-messages 360 --formatter-property print.timestamp=true"
vm "$C | grep -m 2 'T11:'"
out=$(vm "$C | grep -m 2 'natal.*T11:'")
printf '%s\n' "$out"
ts=$(printf '%s\n' "$out" | grep -o 'CreateTime:[0-9]*' | head -1 | cut -d: -f2)
vm "date -d @${ts:0:10} '+%F %T %z'"

# out-of-order
block disorder
vm "kafka-console-consumer.sh $K --topic late --from-beginning --max-messages 360 2>/dev/null \\
  | jq -r '.at[:19] + \"Z\" | fromdate' \\
  | awk '\$1 > seen { seen = \$1 } { behind = seen - \$1 }
         behind > 0 { late++ } behind > 60 { minute++ } behind > 3600 { hour++ }
         END { print NR, \"sales,\", late, \"out of order:\", minute, \"by over a minute,\", hour, \"by over an hour\" }'"

# counting-by-arrival
block per-hour
vm 'python per_minute.py --size 60'
block per-minute
vm 'python per_minute.py --from 13:58 --to 14:03'

# clocks-lie
block ahead
vm 'python clock_ahead.py 2 clocks'
vm 'python clock_ahead.py 0.5 clocks'
block ahead-appended
vm 'python clock_ahead.py 2 appended'

# timestamps-in-kafka
block find-time
vm "date -d '2026-03-02 13:00 -03:00' +%s%3N"
vm "kafka-get-offsets.sh $K --topic late --time 1772467200000"
block find-time-read
vm "kafka-topics.sh $K --create --topic late-sold --partitions 1 --config retention.ms=-1"
vm 'python late_tills.py --topic late-sold --stamp sold'
vm "kafka-get-offsets.sh $K --topic late-sold --time 1772467200000"
block sold-backwards
vm "kafka-console-consumer.sh $K --topic late-sold --from-beginning --max-messages 360 --formatter-property print.offset=true --formatter-property print.timestamp=true | grep -m 2 'natal.*T11:'"
