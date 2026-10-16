#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l04.txt
#
# Needs the machine lessons 1 and 3 build: the cluster, HDFS with
# /raw/clicks-2025.csv in it, and the data generate.py wrote. Every program is
# taken out of the lesson's .md by `lab.sh extract`.
#
# MapReduce runs on Hadoop's local runner, as the lesson says: no
# mapreduce.framework.name is set anywhere, so every task is a thread in the one
# Java process `hadoop jar` starts. Lesson 12 runs the same command on YARN.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Hadoop 3.5.0, Spark 4.1.3, Python 3.12,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-15.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }
STREAM='hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3'
COUNTERS="sed -n '/mapreduce.Job: Counters/,\$p'"

lab start >/dev/null 2>&1
lab exec 'sh hdfs.sh start' >/dev/null 2>&1; sleep 15
lab exec 'hdfs dfs -rm -r -f /out; rm -f *.log' >/dev/null 2>&1

put by-hand.md mapper.py
put by-hand.md reducer.py
block pipe
on "time (zcat data/raw/clicks/day=2025-03-14/*.gz | tail -n +2 | python3 mapper.py | sort | python3 reducer.py)"

block streaming
on "time $STREAM -files mapper.py,reducer.py -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds 2> kinds.log"
block streaming-out
on 'hdfs dfs -ls /out/kinds'
on 'hdfs dfs -cat /out/kinds/part-00000'
block counters
on "$COUNTERS kinds.log | grep -E 'Map (input|output) records|materialized|Reduce (shuffle bytes|input groups)|Spilled|FILE: Number of bytes written'"

block combiner
on "time $STREAM -files mapper.py,reducer.py -mapper 'python3 mapper.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds-combined 2> combined.log"
on "$COUNTERS combined.log | grep -E 'Combine|Reduce shuffle bytes|Spilled'"

block two-reducers
on "$STREAM -files mapper.py,reducer.py -mapper 'python3 mapper.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -numReduceTasks 2 -input /raw/clicks-2025.csv -output /out/kinds-two 2> two.log"
on 'hdfs dfs -ls /out/kinds-two'
on 'hdfs dfs -cat /out/kinds-two/part-00000'
on 'hdfs dfs -cat /out/kinds-two/part-00001'

put two-jobs.md per_visitor.py
put two-jobs.md histogram.py
put two-jobs.md two_steps.py
block chain
on "time $STREAM -files per_visitor.py,reducer.py -mapper 'python3 per_visitor.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/per-visitor 2> job1.log"
on "time $STREAM -files histogram.py,reducer.py -mapper 'python3 histogram.py' -reducer 'python3 reducer.py' -input /out/per-visitor -output /out/histogram 2> job2.log"
on "$COUNTERS job1.log | grep -E 'Reduce output records'"
on 'hdfs dfs -du -s -h /out/per-visitor'
on 'hdfs dfs -cat /out/histogram/part-00000 | sort -n | head -n 3'
on 'hdfs dfs -cat /out/histogram/part-00000 | sort -n | tail -n 2'
on 'hdfs dfs -cat /out/histogram/part-00000 | wc -l'
block spark-two
on 'time spark-submit two_steps.py'
