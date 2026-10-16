#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l12.txt
#
# Needs the machine lessons 1 and 3 build: the standalone cluster, Hadoop
# 3.5.0 with lesson 3's HDFS (hdfs.sh) holding /raw/clicks-2025.csv, lesson
# 4's mapper.py and reducer.py, and the silver layer of lesson 5. Every program
# is taken out of the lesson's .md by `lab.sh extract`; the sh blocks that
# only stop and start things are run from the .md by `lab.sh fence`, silently.
#
# Everything this lesson creates is removed first: YARN's configuration is
# rewritten by yarn.sh, and HBase, its directories, the metastore and the
# output directories in HDFS are deleted.
#
# THE HBASE RELEASE WAS NOT FETCHED BY THE LESSON'S curl LINES: the same file
# and its .sha512, from downloads.apache.org, were cached in /var/cache/bigdata
# beforehand and copied into ~ana; the two checksum lines run on the copy.
#
# The hbase shell is given its commands in a file, which ends in `exit`; read
# from a file without it, the shell waits for more.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Hadoop 3.5.0, Spark 4.1.3, HBase
# 2.6.7, Python 3.13, 4 cores, TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }
quiet() { lab exec "$1" >/dev/null 2>&1; }

lab start >/dev/null 2>&1
quiet 'stop-thriftserver.sh; stop-hbase.sh; sh yarn.sh stop; sh hdfs.sh start; hdfs dfsadmin -safemode wait
       hdfs dfs -rm -r -f -skipTrash /out/kinds-yarn /out/kinds-q /hbase /hbase-in
       rm -rf ~/hbase ~/hbase-2.6.7-hadoop3 ~/hbase-zk metastore_db spark-warehouse look.rb
       sed -i "/hbase\/bin/d" ~/.sparkrc'
cp /var/cache/bigdata/hbase-2.6.7-hadoop3-bin.tar.gz* /home/ana/ && chown ana:ana /home/ana/hbase-2.6.7-hadoop3-bin.tar.gz*
put yarn.md yarn.sh
put spark-on-yarn.md kinds_yarn.py
put queues.md queues.sh
put the-metastore.md metastore.py
put the-metastore.md by_name.py
put hbase.md to_hbase.py
quiet "$(lab fence "$HERE/the-ecosystem.md" 1)"

block yarn-start
on 'sh yarn.sh setup'
on 'sh yarn.sh start'
sleep 30
on 'yarn node -list 2>/dev/null'
on 'mapred queue -list 2>/dev/null'
block streaming-yarn
on "time hadoop jar \$HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.job.queuename=nightly -files mapper.py,reducer.py -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds-yarn 2> kinds-yarn.log"
on 'hdfs dfs -cat /out/kinds-yarn/part-00000'
block streaming-counters
on "grep -E 'Launched (map|reduce) tasks|Killed map tasks|local map tasks' kinds-yarn.log"
block spark-yarn
on 'time HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop spark-submit --master yarn --deploy-mode cluster --queue analysts --driver-memory 512m --executor-memory 512m --num-executors 1 --conf spark.driver.memoryOverhead=256m --conf spark.executor.memoryOverhead=256m kinds_yarn.py'
on 'yarn application -list -appStates FINISHED 2>/dev/null'
APP=$(lab exec "yarn application -list -appStates FINISHED 2>/dev/null | grep -o 'application_[0-9_]*' | sort | tail -1")
on "yarn logs -applicationId $APP -log_files stdout 2>/dev/null | grep -v '^\$'"
block queues
on 'sh queues.sh'
quiet "$(lab fence "$HERE/queues.md" 1)"
sleep 10
block metastore
on 'spark-submit metastore.py 2>/dev/null'
block by-name
on 'spark-submit by_name.py 2>/dev/null'
block thrift
on 'start-thriftserver.sh'
sleep 45
on "beeline -u jdbc:hive2://localhost:10000 -n ana --silent=true -e 'SHOW TABLES IN shop; SELECT kind, count(*) AS events FROM shop.clicks WHERE day = \"2025-03-14\" GROUP BY kind ORDER BY kind;'"
quiet 'stop-thriftserver.sh'
quiet "cd ~ && $(lab fence "$HERE/hbase.md" 1 | grep -v '^curl ' | grep -v '^sha512sum\|^cut ')"
sleep 30
block hbase-sha
for c in "sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1" \
         "cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \\n' | tr A-F a-f; echo"; do
  printf 'ana@lab:~$ %s\n' "$c"; printf 'cd ~ && %s\n' "$c" > /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1
done
block hbase-load
on 'spark-submit to_hbase.py 2>/dev/null'
on "echo \"create 'events', 'e'\" | hbase shell -n 2>/dev/null; echo"
on 'time hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=HBASE_ROW_KEY,e:kind,e:book,e:device events hdfs://localhost:9000/hbase-in/january 2> import.log'
on "grep -E 'Map input records|Bad Lines' import.log | tail -2"
quiet "$(lab fence "$HERE/hbase.md" 2)"
block hbase-query
on 'hbase shell -n look.rb 2>/dev/null'
quiet "$(lab fence "$HERE/what-survived.md" 1)"
