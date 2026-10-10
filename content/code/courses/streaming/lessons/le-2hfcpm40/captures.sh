#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of streaming (Spark Structured
# Streaming), as a script that produces them. Its output is not committed.
#
#   sudo bash lab.sh files
#   sudo bash lessons/le-2hfcpm40/captures.sh > /tmp/le-2hfcpm40.out 2>&1
#
# STAGED, not typed, and said here: the lab starts from a fresh one-node
# cluster (lab reset 1) with no ~/spark and no ~/.ivy2.5.2, so the connector
# download in reading-kafka is a real first run; the SPARK_LOCAL_IP line is
# removed from ~/.profile before the install section is run again, so it is
# there once; between deleting and re-creating `sales` in triggers the
# script waits two seconds. The query in triggers runs in a second terminal
# and is stopped with Ctrl-C (SIGINT) after the till has finished.
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
while IFS= read -r -d '' name && IFS= read -r -d '' body; do
  printf '%s' "$body" | put "$name"
done < <(extract)

lab reset 1 >/dev/null 2>&1
run 'rm -rf ~/spark ~/.ivy2.5.2 ~/work/spark.log; sed -i "/SPARK_LOCAL_IP/d" ~/.profile' >/dev/null
lab install le-2hfcpm40 installing-spark.md >/dev/null 2>&1

# installing-spark
block pip-show
vm 'pip show pyspark | head -2'
block du
vm 'du -sh ~/venv/lib/python3.12/site-packages/pyspark'
block version
vm 'spark-submit --version'

# reading-kafka
block topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
block tills
vm 'python tills.py --count 200 --rate 0'
block raw
vm 'python spark_raw.py 2>spark.log'
block jars
vm 'ls ~/.ivy2.5.2/jars'

# a-windowed-count
block update
vm 'python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log'
block complete
vm 'python spark_sales.py --mode complete --checkpoint ~/spark/ckpt/complete 2>spark.log'
block append
vm 'python spark_sales.py --mode append --checkpoint ~/spark/ckpt/append 2>spark.log'

# checkpoints
block ckpt-ls
vm 'ls ~/spark/ckpt/update ~/spark/ckpt/update/state/0'
block ckpt-offsets
vm 'tail -1 ~/spark/ckpt/update/offsets/5'
block rerun
vm 'python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log'
block two-more
vm "printf '%s\n' 'recife|{\"sale\": \"rec-000201\", \"shop\": \"recife\", \"book\": \"bk-03\", \"qty\": 1, \"cents\": 2990, \"at\": \"2026-03-02T09:38:00-03:00\"}' 'natal|{\"sale\": \"nat-000202\", \"shop\": \"natal\", \"book\": \"bk-01\", \"qty\": 1, \"cents\": 3990, \"at\": \"2026-03-02T09:21:00-03:00\"}' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property 'key.separator=|'"
block rerun2
vm 'python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log'
block groups
vm 'kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list'

# triggers
block delete
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic sales'
sleep 2
block recreate
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
term2 live 'python spark_sales.py --trigger 5 --checkpoint ~/spark/ckpt/live 2>spark.log' 15
block live-tills
vm 'python tills.py --count 100 --rate 10'
sleep 8
block jps
vm 'jps -l'
block ps
vm 'ps -o pid,rss,comm -u ubuntu --sort=-rss | head -5'
block ss
vm 'ss -ltn | grep -E "4040|9092"'
block live
stop2 live
block continuous
vm 'python spark_sales.py --trigger continuous --checkpoint ~/spark/ckpt/cont 2>spark.log; grep AnalysisException spark.log'

# sinks
block kafka-sink
vm 'python spark_sales.py --sink kafka --checkpoint ~/spark/ckpt/kafka 2>spark.log'
block kafka-read
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-per-window --from-beginning --formatter-property print.key=true --max-messages 5'
block files-update
vm 'python spark_sales.py --sink files --checkpoint ~/spark/ckpt/files 2>spark.log; tail -1 spark.log'
block files-append
vm 'python spark_sales.py --sink files --mode append --checkpoint ~/spark/ckpt/files-append 2>spark.log'
block files-ls
vm 'ls ~/spark/out ~/spark/out/_spark_metadata'
block files-cat
vm 'cat ~/spark/out/part-*.json'
