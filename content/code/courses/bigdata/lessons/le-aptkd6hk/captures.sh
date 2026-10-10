#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l01.txt
#
# SECTIONS 03 AND 04 ARE THE STUDENT'S SETUP, RUN FOR REAL. `lab.sh wipe`
# removes Spark, ~/.sparkrc and the line in ~/.bashrc, and the install block of
# the-lab.md is then run as the lesson shows it, taken out of the .md. Two of its
# lines are not run here: apt-get, which ran once on 2026-10-10 and whose output
# is a page of package names, and the two `curl -O`, whose files are copied from
# /var/cache/bigdata, where the same commands put them on 2026-10-10. The
# configuration block of the-cluster.md is run whole, taken out of the .md.
#
# Every program the lesson shows (generate.py, visitors.py, buckets.py and
# visitors_spark.py) is taken out of the lesson's .md by `lab.sh extract` and
# written into ~/big before it runs.
#
# THE FAILURES of section 06 are taken by breaking one step each: a copy of the
# release cut to its first 100 MB; a shell that has not read ~/.sparkrc; the
# cluster stopped; and the master started with no worker, the job stopped by
# `timeout` after 40 seconds.
#
# THE MEMORY LIMIT of sections 08 and 09 is `ulimit -v`, typed as shown. It
# stands in for a machine with 1 GB to spare, and the lesson says so.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.12, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; lab exec "$*" 2>&1; }
onh() { printf 'ana@lab:~$ %s\n' "$*"; lab exec "cd ~ && $*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab wipe
cp /var/cache/bigdata/spark-4.1.3-bin-hadoop3.tgz* /home/ana/ && chown ana:ana /home/ana/spark-4.1.3-bin-hadoop3.tgz*
lab exec "cd ~ && $(lab fence "$HERE/the-lab.md" 2 | grep -v -e '^sudo apt-get' -e '^curl ' -e '^mkdir ~/big$')"

block install
onh 'sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512'
onh 'java -version'
onh 'spark-submit --version'

lab exec "$(lab fence "$HERE/the-cluster.md" 1)"
block start
on 'start-master.sh'
on 'start-worker.sh spark://localhost:7077'
sleep 12
block workers
on "curl -s localhost:8080/json/ | jq -c '.workers[] | {host, port, cores, memory, state}'"

block generate
put the-data.md generate.py
on 'time spark-submit generate.py'
block data-files
on 'ls data/raw/clicks | head -3'
on 'ls data/raw/clicks | wc -l'
on 'du -sh data/raw/clicks data/raw/books'
on 'zcat data/raw/clicks/*/*.gz | wc -c'
block data-head
on 'zcat data/raw/clicks/day=2025-03-14/*.gz | head -5'

block oom-free
put out-of-memory.md visitors.py
on 'time python3 visitors.py'
block oom-limit
on '(ulimit -v 1000000; time python3 visitors.py)'

block buckets-run
put split-by-key.md buckets.py
on '(ulimit -v 1000000; time python3 buckets.py)'
block buckets-sizes
on 'ls -lS buckets | head -4'
on 'ls -lS buckets | tail -2'
on 'du -sh buckets'

block spark-run
put scale-up-or-out.md visitors_spark.py
on 'time spark-submit visitors_spark.py'

block fail-checksum
lab exec 'mkdir -p /tmp/broken && head -c 100000000 ~/spark-4.1.3-bin-hadoop3.tgz > /tmp/broken/spark-4.1.3-bin-hadoop3.tgz && cp ~/spark-4.1.3-bin-hadoop3.tgz.sha512 /tmp/broken/'
printf 'ana@lab:~$ %s\n' 'sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512'
lab exec 'cd /tmp/broken && sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512' 2>&1
lab exec 'rm -rf /tmp/broken'

block fail-path
printf 'ana@lab:~/big$ %s\n' 'spark-submit generate.py'
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin bash -c 'cd ~/big && spark-submit generate.py' 2>&1

lab stop
block fail-master
on "spark-submit visitors_spark.py 2>&1 | grep -E 'WARN|ERROR'"

lab exec 'start-master.sh' >/dev/null; sleep 6
block fail-workers
on "timeout 40 spark-submit visitors_spark.py 2>&1 | grep -E 'WARN|ERROR'"
lab stop
lab start
