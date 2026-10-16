#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo -E bash ../le-3jer9wbw/captures.sh > /dev/null   # lesson 8 first:
#   sudo -E bash captures.sh > out.txt                      # this continues it
#
# It continues the state lesson 8's captures leave (the feature store with
# tonight's snapshot, scores.db holding the night of 28 February, the service's
# libraries installed). The service is started in the background the way the
# lesson starts it in a second terminal, and stopped by pid. Every timing, and
# the memory the service holds, changes on every run.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9
F="python3 $COURSE/lab/fences.py"; L9=$COURSE/lessons/le-mh87rchm

quiet lab exec 'pkill -u ana -f "[u]vicorn serve" || true; rm -f requests.log scores.db; python featurestore.py snapshot 2026-02-28 && python score_batch.py 2026-02-28'

stage serve.py le-mh87rchm/logging-requests.md
quiet lab exec "(setsid $($F block $L9/logging-requests.md 'uvicorn serve:app --port 8000') > /tmp/uvicorn.log 2>&1 < /dev/null &); for i in \$(seq 60); do curl -s -o /dev/null http://127.0.0.1:8000/docs && break; sleep 1; done; : > requests.log"
block logging-requests
on 'curl -s http://127.0.0.1:8000/lapse/2; echo'
on 'curl -s http://127.0.0.1:8000/lapse/8; echo'
on 'tail -2 requests.log'

stage load.py le-mh87rchm/under-load.md
stage latency.py le-mh87rchm/under-load.md
block under-load
on 'python load.py 2000 8'
on 'python latency.py 2000'

block percentiles
on 'for n in 1 4 16; do python load.py 600 $n; python latency.py 600; done'

block cost
on 'ps -o rss=,comm= -C uvicorn'
quiet lab exec 'pkill -u ana -f "[u]vicorn serve" || true'
block cost
on 'time python score_batch.py 2026-02-28'

block watching-the-scores
on 'for night in 2026-02-01 2026-02-08 2026-02-15 2026-02-22; do python score_batch.py $night; done'
stage watch.py le-mh87rchm/watching-the-scores.md
block watching-the-scores
on 'python watch.py 2026-02-28; echo "exit status $?"'

block a-broken-night
on "sqlite3 features.db \"UPDATE offline SET spend_180d = spend_180d * 100 WHERE as_of = '2026-02-28'\""
on 'python score_batch.py 2026-02-28'
on 'python watch.py 2026-02-28; echo "exit status $?"'
block a-broken-night
on 'python featurestore.py snapshot 2026-02-28 && python score_batch.py 2026-02-28'
on 'python watch.py 2026-02-28; echo "exit status $?"'

stage report_card.py le-mh87rchm/the-report-card.md
block the-report-card
on 'python score_batch.py 2025-11-30'
on 'python report_card.py 2025-11-30'
on 'python report_card.py 2026-02-28'
