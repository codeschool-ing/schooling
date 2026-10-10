#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-2q5apnvb.out 2>&1
#
# STAGED, not typed, and said here: the lab starts from a fresh one-node
# cluster, and the files the consumers write are deleted first, so each
# count starts from zero. The crashes are the programs' own `os._exit`,
# which ends a process the way a power cut or a kill -9 does: no cleanup,
# no final commit. A lost acknowledgement (where-it-breaks) is NOT provoked:
# it needs a network that drops one answer, which this lab does not have.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1 >/dev/null
run 'rm -f processed-most.txt processed-least.txt' >/dev/null

block sales
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 1'
vm 'python tills.py --count 50 --rate 0'

block most
vm 'python crash_consumer.py most --crash-after 25'
vm 'python crash_consumer.py most'
vm 'wc -l < processed-most.txt'
vm 'sort processed-most.txt | uniq | wc -l'

block least
vm 'python crash_consumer.py least --crash-after 25'
vm 'python crash_consumer.py least'
vm 'wc -l < processed-least.txt'
vm 'sort processed-least.txt | uniq -d'

block dump-plain
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-0/00000000000000000000.log | head -4'
block idem
vm 'python idempotent.py'
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-0/00000000000000000000.log | tail -1'

block txn
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic ledger --partitions 1'
vm 'python txn.py'
block isolation
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic ledger --from-beginning --timeout-ms 5000 2>/dev/null'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic ledger --from-beginning --timeout-ms 5000 --isolation-level read_committed 2>/dev/null'
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic ledger'
vm 'kafka-dump-log.sh --files ~/kafka-data/node1/log/ledger-0/00000000000000000000.log'

block eos
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic big-sales --partitions 1'
vm 'python eos_copy.py --crash-after 25'
vm 'python eos_copy.py'
block eos-count
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic big-sales --from-beginning --timeout-ms 5000 --isolation-level read_committed 2>/dev/null | wc -l'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic big-sales --from-beginning --timeout-ms 5000 2>/dev/null | wc -l'
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --from-beginning --timeout-ms 5000 2>/dev/null | jq -c "select(.cents >= 10000)" | wc -l'
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group eos-copy 2>/dev/null'
