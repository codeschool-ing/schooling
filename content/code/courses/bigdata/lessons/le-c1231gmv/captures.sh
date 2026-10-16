#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l11.txt
#
# Needs the machine lesson 1 builds, with the cluster running, and the silver
# layer of lesson 5. Every program is taken out of the lesson's .md by
# `lab.sh extract`.
#
# THE FOUR JARS WERE NOT FETCHED BY THE LESSON'S curl LINES. The machine this
# was recorded on cannot reach repo1.maven.org, so the same files were fetched
# from Google's mirror of Maven Central,
#   https://maven-central.storage-download.googleapis.com/maven2/<same path>,
# checked against Maven's own .sha1 for each, kept in /var/cache/bigdata/jars
# and copied into ~ana/jars here. They are the same bytes; the `ls -l` below
# shows their sizes.
#
# delta_maintenance.py and hudi_basics.py are run with 2>/dev/null, as the
# lesson shows and says why: both print pages of warnings about table
# configuration that the lesson does not discuss.
#
# Every table directory is removed first, so each program starts from no
# table and the version numbers start at 0.
#
# Timings are not quoted. Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3,
# Python 3.13, Delta Lake 4.3.1, Iceberg 1.12.0, Hudi 1.2.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
lab exec 'rm -rf data/plain data/delta data/iceberg data/hudi ~/jars; mkdir -p ~/jars' >/dev/null 2>&1
cp /var/cache/bigdata/jars/*.jar /home/ana/jars/ && chown ana:ana /home/ana/jars/*.jar
put what-a-lake-cannot-do.md plain_append.py
put delta-in-practice.md delta_basics.py
put compaction-and-vacuum.md delta_maintenance.py
put iceberg.md iceberg_basics.py
put hudi.md hudi_basics.py
DELTA='$HOME/jars/delta-spark_2.13-4.3.1.jar,$HOME/jars/delta-storage-4.3.1.jar'

block plain-append
on 'spark-submit plain_append.py'
block jars
on 'ls -l ~/jars'
block delta-basics
on "spark-submit --jars $DELTA delta_basics.py"
block delta-log
on "jq -c 'keys[0]' data/delta/purchases/_delta_log/00000000000000000002.json | sort | uniq -c"
on "jq -c 'select(.add) | .add | {path, size, rows: (.stats | fromjson | .numRecords)}' data/delta/purchases/_delta_log/00000000000000000002.json"
block delta-maintenance
on "spark-submit --jars $DELTA delta_maintenance.py 2>/dev/null"
block iceberg
on 'spark-submit --jars $HOME/jars/iceberg-spark-runtime-4.1_2.13-1.12.0.jar iceberg_basics.py'
block iceberg-files
on "ls data/iceberg/shop/purchases/metadata | grep -v crc"
block hudi
on 'spark-submit --jars $HOME/jars/hudi-spark4.1-bundle_2.13-1.2.1.jar hudi_basics.py 2>/dev/null'
block hudi-timeline
on 'ls data/hudi/purchases/.hoodie/timeline'
