#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l03.txt
#
# Needs the machine lesson 1 builds and the data generate.py wrote.
#
# SECTION 04 IS THE STUDENT'S SETUP, RUN FOR REAL: Hadoop is removed with
# everything HDFS held, ~/.sparkrc loses its Hadoop lines, and the install block
# of installing-hdfs.md is run as the lesson shows it, taken out of the .md. Its
# two `curl -O` lines are not run; their files are copied from
# /var/cache/bigdata, where the same commands put them on 2026-10-10.
#
# The virtual environment of section 09 is created by the lesson's own three
# commands, taken out of object-storage.md; pip's output is not quoted.
#
# hdfs.sh, hdfs_count.py and s3_demo.py are taken out of the lesson's .md by
# `lab.sh extract`.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Hadoop 3.5.0, Spark 4.1.3, Python 3.12,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-15.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
# The command goes through a file, so that no wrapper's own command line holds
# the words a `pgrep -f` in it is looking for.
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
onh() { printf 'ana@lab:~$ %s\n' "$*"; lab exec "cd ~ && $*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab exec '[ -f hdfs.sh ] && sh hdfs.sh stop' >/dev/null 2>&1
lab exec 'pkill -u ana -f [m]oto_server' >/dev/null 2>&1
lab exec 'rm -rf ~/hdfs ~/hadoop ~/hadoop-3.5.0 ~/hadoop-3.5.0.tar.gz* ~/s3-env ~/moto.log'
lab exec "sed -i -e '/JAVA_HOME/d' -e '/HADOOP_HOME/d' ~/.sparkrc"
cp /var/cache/bigdata/hadoop-3.5.0.tar.gz* /home/ana/ && chown ana:ana /home/ana/hadoop-3.5.0.tar.gz*
lab exec "cd ~ && $(lab fence "$HERE/installing-hdfs.md" 1 | grep -v '^curl ' | grep -v '^sha512sum')"

block install
onh 'sha512sum -c hadoop-3.5.0.tar.gz.sha512'
onh 'hadoop version | head -n 1'

put installing-hdfs.md hdfs.sh
block setup
on 'sh hdfs.sh setup'
block start
on 'sh hdfs.sh start'
sleep 20
on "hdfs dfsadmin -report | grep -E '^(Live|Name)'"

block put
on 'hdfs dfs -mkdir -p /raw'
on "time (zcat data/raw/clicks/*/*.gz | grep -v '^event_id' | hdfs dfs -put - /raw/clicks-2025.csv)"
on 'hdfs dfs -ls -h /raw'
block blocks
on "hdfs fsck /raw/clicks-2025.csv -files -blocks -locations | grep -E '^[0-9]+\.' | sed -E 's/BP-[^:]*://; s/DatanodeInfoWithStorage\[//g; s/,DS-[^]]*\]//g'"
block block-files
B=$(lab exec "hdfs fsck /raw/clicks-2025.csv -files -blocks 2>/dev/null | grep -oE 'blk_[0-9]+' | head -n 1")
on "find ~/hdfs -name '${B}*' | xargs ls -l"

block small-put
on 'time hdfs dfs -put data/raw/clicks /raw/clicks-daily'
block small-fsck
on "hdfs fsck /raw/clicks-2025.csv | grep -E 'Total (size|files|blocks)'"
on "hdfs fsck /raw/clicks-daily | grep -E 'Total (size|files|blocks)'"

lab start >/dev/null 2>&1
put spark-reads-hdfs.md hdfs_count.py
block spark-hdfs
on 'spark-submit hdfs_count.py'

block kill-dn
on 'kill -9 $(cat ~/hdfs/dn2/hadoop-ana-datanode.pid)'
block rereplicate
on "for i in \$(seq 15); do sleep 10; echo \"\$(date +%T) \$(hdfs dfsadmin -report -dead | grep -c '^Name') dead, \$(hdfs fsck /raw/clicks-2025.csv | grep 'Under-replicated')\"; done"
lab exec 'sh hdfs.sh stop; sh hdfs.sh start' >/dev/null 2>&1

# pip needs the sandbox's proxy, which ana's clean environment does not carry.
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin HTTPS_PROXY="$HTTPS_PROXY" \
  PIP_CERT=/etc/ssl/certs/ca-certificates.crt bash -c "cd ~ && $(lab fence "$HERE/object-storage.md" 1)" >/dev/null 2>&1
sleep 5
put object-storage.md s3_demo.py
block s3-demo
on '~/s3-env/bin/python s3_demo.py'
block hdfs-mv
on 'time hdfs dfs -mv /raw/clicks-2025.csv /raw/clicks-2025-moved.csv'
lab exec 'hdfs dfs -mv /raw/clicks-2025-moved.csv /raw/clicks-2025.csv'
