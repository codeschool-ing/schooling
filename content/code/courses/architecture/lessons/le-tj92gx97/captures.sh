#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The four files of ~/lab/brokers are EXTRACTED from the section "Two brokers
# in your lab" (the-brokers.md), as the copy button hands them over, and the
# shell function `kafka` from "Kafka in practice" (kafka-in-practice.md): each
# Kafka command below runs with that function defined first, as it is in the
# student's shell, and the transcript shows only the command typed.
# Staged: the tools image is built beforehand (lab.sh, "prebuild"); the brokers
# get 20 seconds to start before the first command. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-tj92gx97
lab reset
at '~/lab/brokers'
for f in compose.yaml Dockerfile publish.py consume.py; do save $L/the-brokers.md $f "~/lab/brokers/$f"; done
KFN=$(python3 - "$COURSE/lessons/$L/kafka-in-practice.md" <<'PY'
import re, sys
md = open(sys.argv[1]).read()
print(re.search(r"```sh\n(kafka\(\) \{.*?\})\n```", md, re.S).group(1))
PY
)
krun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $KFN && { $1 ; }" 2>&1 || true; }
prebuild
quiet 'docker compose up -d'
sleep 20
block brokers-up
run 'docker compose ps --format "{{.Service}} {{.Image}} {{.Status}}"'
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"'
block nobody
run 'docker compose --progress quiet run --rm tools python publish.py 2'
run 'docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet'
block declare
run 'docker compose --progress quiet run --rm tools python consume.py email'
run 'docker compose --progress quiet run --rm tools python consume.py warehouse'
block four
run 'docker compose --progress quiet run --rm tools python publish.py 4 3'
run 'docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet'
block email
run 'docker compose --progress quiet run --rm tools python consume.py email'
block competing
run 'docker compose --progress quiet run --rm tools python publish.py 6 7 > /dev/null'
run 'docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet'
run 'for i in 1 2; do docker compose --progress quiet run --rm tools python consume.py warehouse & done; wait'
block empty
run 'docker compose exec rabbitmq rabbitmqctl list_queues name messages --quiet'
block topic
krun 'kafka topics --create --topic orders --partitions 3'
krun 'kafka topics --describe --topic orders'
block produce
krun 'printf "ana:order 1\nbruno:order 2\nana:order 3\ncarla:order 4\nbruno:order 5\n" | kafka console-producer --topic orders --property parse.key=true --property key.separator=:'
block consume
krun 'kafka console-consumer --topic orders --group email --from-beginning --max-messages 5 --property print.partition=true --property print.offset=true --property print.key=true'
block group
krun 'kafka consumer-groups --describe --group email'
block lag
krun 'printf "ana:order 6\ncarla:order 7\n" | kafka console-producer --topic orders --property parse.key=true --property key.separator=:'
krun 'kafka consumer-groups --describe --group email'
block warehouse
krun 'kafka console-consumer --topic orders --group warehouse --from-beginning --max-messages 7 --property print.partition=true --property print.key=true'
block rewind
krun 'kafka consumer-groups --group email --reset-offsets --to-earliest --topic orders --execute'
krun 'kafka consumer-groups --describe --group email'
quiet 'docker compose down -v'
