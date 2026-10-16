#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of streaming (Flink and Kafka
# Streams), as a script that produces them. Its output is not committed.
#
#   sudo bash lessons/le-wc22exj7/captures.sh > /tmp/le-wc22exj7.out 2>&1
#
# STAGED, not typed, and said here: the lab starts from a fresh one-node
# cluster (lab reset 1) with no ~/flink, no Flink download, no
# ~/streams-state and no checkpoints or savepoints, and the install section
# is then run as the student types it. The Kafka Streams copies and their
# Ctrl-C run in second and third terminals. Between submitting a Flink job
# and reading its output the script waits 25 seconds; the job id, the
# savepoint path and the checkpoint directory are taken from what the
# commands before them printed, so the commands shown carry this run's
# random ids.
# NOT RUN: nothing is left out; every command the lesson shows is here.
. "$(dirname "$0")/../../lab/capture-lib.sh"
L=$(cd "$(dirname "$0")" && pwd)

# This lesson's programs, taken from its own .md exactly as `lab.sh files`
# takes them (that command stops at the first broken draft of any lesson).
extract() {
  python3 - "$L" <<'PY'
import glob, json, re, sys
pat = re.compile(r"^[^\n]*`~/work/([\w.-]+)`[^\n]*:\n\n```([\w-]*)\n(.*?)^```$", re.S | re.M)
for md in sorted(glob.glob(sys.argv[1] + "/*.md")):
    if md.endswith(".pt.md"):
        continue
    for name, lang, body in pat.findall(open(md, encoding="utf-8").read()):
        if lang == "schooling-example":
            body = "\n".join(p["code"] for p in json.loads(body)["parts"]) + "\n"
        sys.stdout.write(name + "\0" + body + "\0")
PY
}
lab reset 1 >/dev/null 2>&1
run '~/flink/bin/stop-cluster.sh >/dev/null 2>&1; rm -rf ~/streams-state ~/flink ~/flink-checkpoints ~/flink-savepoints ~/flink-2.2.1-bin-scala_2.12.tgz* ~/.flink-sql-history ~/work/*.class' >/dev/null
while IFS= read -r -d '' name && IFS= read -r -d '' body; do
  printf '%s' "$body" | put "$name"
done < <(extract)

# kafka-streams
block topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
block tills
vm 'python tills.py --count 200 --rate 0'
block javac
vm 'javac -cp "$HOME/kafka/libs/*" SalesPerShop.java'
term2 ksa 'java -cp "$HOME/kafka/libs/*:." SalesPerShop a' 20
block per-book
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-per-book --from-beginning --formatter-property print.key=true --formatter-property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --timeout-ms 5000 2>/dev/null'
block ksa
stop2 ksa

# streams-state
block list
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --list'
block state-dir
vm 'ls ~/streams-state/a/sales-per-shop'
term2 ksa2 'java -cp "$HOME/kafka/libs/*:." SalesPerShop a' 20
block ps-streams
vm 'ps -o pid,rss,comm -u ubuntu --sort=-rss | head -4'
term2 ksb 'java -cp "$HOME/kafka/libs/*:." SalesPerShop b' 25
block members
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group sales-per-shop --members'
block ksb
stop2 ksb
block ksa2
stop2 ksa2

# installing-flink
lab install le-wc22exj7 installing-flink.md >/dev/null 2>&1
block sha-file
home 'sha512sum flink-2.2.1-bin-scala_2.12.tgz | cut -d" " -f1'
block sha-published
home 'cut -d" " -f1 flink-2.2.1-bin-scala_2.12.tgz.sha512'
block config
home 'grep -n -E "size: |bind-address: localhost" ~/flink/conf/config.yaml'
block start
home '~/flink/bin/start-cluster.sh'
sleep 10
block ports
home 'ss -ltn | grep -E ":8081|:6123"'

# flink-sql
block submit1
vm '~/flink/bin/sql-client.sh -f sales.sql 2>/dev/null | grep "Job ID"'
sleep 25
block read1
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null'
block list1
vm '~/flink/bin/flink list'
id=$(run '~/flink/bin/flink list 2>/dev/null' | awk '/RUNNING/ {print $4}')
block cancel
vm "~/flink/bin/flink cancel $id"
block sed
vm "sed -i \"1i SET 'table.exec.source.idle-timeout' = '5 s';\" sales.sql"
block submit2
vm '~/flink/bin/sql-client.sh -f sales.sql 2>/dev/null | grep "Job ID"'
sleep 25
block read2
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null'

# flink-state
block ckpts
vm 'ls ~/flink-checkpoints'
id=$(run '~/flink/bin/flink list 2>/dev/null' | awk '/RUNNING/ {print $4}')
block stop
out=$(vm "~/flink/bin/flink stop --savepointPath file:///home/ubuntu/flink-savepoints $id")
printf '%s\n' "$out"
sp=$(printf '%s\n' "$out" | sed -n 's/^Savepoint completed. Path: //p')
block two-more
vm "printf '%s\n' 'recife|{\"sale\": \"rec-000201\", \"shop\": \"recife\", \"book\": \"bk-03\", \"qty\": 1, \"cents\": 2990, \"at\": \"2026-03-02T09:38:00-03:00\"}' 'natal|{\"sale\": \"nat-000202\", \"shop\": \"natal\", \"book\": \"bk-01\", \"qty\": 1, \"cents\": 3990, \"at\": \"2026-03-02T09:44:00-03:00\"}' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property 'key.separator=|'"
block restore
vm "~/flink/bin/sql-client.sh -Dexecution.state-recovery.path=$sp -f sales.sql 2>/dev/null | grep \"Job ID\""
sleep 25
block read3
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null'
block jps
vm 'jps -l'
block ps-flink
vm 'ps -o pid,rss,comm -u ubuntu --sort=-rss | head -4'
block stop-cluster
vm '~/flink/bin/stop-cluster.sh'
