#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l05.txt
#
# Needs the machine lesson 1 builds, with the cluster running and the data
# generate.py wrote. Every program is taken out of the lesson's .md by
# `lab.sh extract`. data/silver is removed first, so that to_parquet.py writes
# it from nothing, as the student's first run does.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.12, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-15.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
lab exec 'rm -rf data/silver metastore_db spark-warehouse derby.log'
for f in rdds:rdd_kinds lazy-evaluation:lazy dataframes:explore schemas:schema python-udfs:udf \
         writing-parquet:to_parquet three-ways:three_ways; do
  put "${f%%:*}.md" "${f##*:}.py"
done

block rdd
on 'spark-submit rdd_kinds.py'
block lazy
on 'spark-submit lazy.py'
block explore
on 'spark-submit explore.py'
block schema
on 'spark-submit schema.py'
block udf
on 'spark-submit udf.py'
block to-parquet
on 'time spark-submit to_parquet.py'
on 'du -sh data/raw/clicks data/silver/clicks'
on 'ls data/silver/clicks/day=2025-03-14'
block spark-sql
on 'time spark-sql -e '"'"'SELECT b.category, count(*) AS purchases FROM parquet.`data/silver/clicks` c JOIN parquet.`data/silver/books` b ON c.book_id = b.book_id WHERE c.kind = "purchase" GROUP BY b.category ORDER BY purchases DESC LIMIT 3'"'"''
block three-ways
on 'spark-submit three_ways.py'
