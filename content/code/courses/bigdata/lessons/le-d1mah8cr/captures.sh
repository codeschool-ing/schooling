#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l10.txt
#
# Needs the machine lesson 1 builds, with the cluster running, the silver
# layer of lesson 5 and lastscan.py of lesson 6. Every program is taken out of
# the lesson's .md by `lab.sh extract`.
#
# THE ENVIRONMENT FOR PYARROW is made by the lesson's own two lines, taken out
# of inside-a-parquet-file.md, after any earlier ~/pq-env has been removed.
# pip's output is not quoted. pip needs the sandbox's proxy, which ana's clean
# environment does not carry, so those two lines run with it passed in.
#
# footer.py reads the first file of a day's directory in sorted order; each
# directory here holds one file.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.13, pyarrow
# 26.0.0, 4 cores, TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
lab exec 'rm -rf ~/pq-env data/tmp' >/dev/null 2>&1
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin HTTPS_PROXY="$HTTPS_PROXY" \
  PIP_CERT=/etc/ssl/certs/ca-certificates.crt bash -c "cd ~ && $(lab fence "$HERE/inside-a-parquet-file.md" 1)" >/dev/null 2>&1
put ../le-z6dqn26k/measuring-a-scan.md lastscan.py
put inside-a-parquet-file.md footer.py
put why-silver-is-larger.md codecs.py
put row-group-skipping.md skipping.py

block footer-silver
on '~/pq-env/bin/python footer.py data/silver/clicks/day=2025-01-01'
block codecs
on 'spark-submit codecs.py'
block footer-v2
on '~/pq-env/bin/python footer.py data/tmp/parquet-v2-zstd-micros/day=2025-01-01'
block skipping
on 'spark-submit skipping.py'
block footer-by-book
on '~/pq-env/bin/python footer.py data/tmp/by-book/day=2025-01-01 book_id'
