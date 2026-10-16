#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../le-h449zbxt/captures.sh > /dev/null   # lesson 7 first:
#   sudo bash captures.sh > out.txt                      # this continues it
#
# It continues the state lesson 7's captures leave (the Git and DVC project,
# MLflow's registry with version 1 as champion and version 2 registered),
# rebuilds lesson 6's feature store with the commands that lesson shows
# (output not quoted), installs this lesson's libraries with its pip line
# (output not quoted), then runs the lesson in order. The web service is
# started in the background the way the lesson starts it in a second
# terminal, and stopped by pid. Dates in HTTP headers and the curl timing
# change on every run.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9
F="python3 $COURSE/lab/fences.py"; L8=$COURSE/lessons/le-3jer9wbw

quiet lab exec 'rm -f features.db scores.db models/*.onnx; pkill -u ana -f "[u]vicorn serve" || true'
quiet lab exec 'python featurestore.py backfill 2025-06-01 2026-02-22 && python featurestore.py snapshot 2026-02-28 && python featurestore.py online'
quiet lab exec "$($F block $L8/installing-the-service.md 'pip install fastapi==0.143.0 uvicorn==0.54.0 skl2onnx==1.20.0 onnxruntime==1.31.0')"

stage score_batch.py le-3jer9wbw/batch-scoring.md
quiet lab exec "$($F block $L8/batch-scoring.md "printf 'scores.db\nmodels/*.onnx\n' >> .gitignore")"
block batch-scoring
on 'python score_batch.py 2026-02-28'

block reruns-and-keys
on 'python score_batch.py 2026-02-28'
on 'sqlite3 -header -column scores.db "SELECT * FROM lapse_scores ORDER BY p_lapse DESC LIMIT 5"'

block installing-the-service
on "pip list 2>/dev/null | grep -iE '^(fastapi|uvicorn|skl2onnx|onnxruntime|onnx) '"

stage serve.py le-3jer9wbw/a-web-service.md
quiet lab exec "(setsid $($F block $L8/a-web-service.md 'uvicorn serve:app --port 8000') > /tmp/uvicorn.log 2>&1 < /dev/null &); for i in \$(seq 60); do curl -s -o /dev/null http://127.0.0.1:8000/docs && break; sleep 1; done"
block calling-it
on 'curl -s http://127.0.0.1:8000/lapse/2; echo'
on 'curl -s -i http://127.0.0.1:8000/lapse/8; echo'
on 'curl -s http://127.0.0.1:8000/lapse/abc; echo'
on 'curl -s -o /dev/null -w "%{time_total}\n" http://127.0.0.1:8000/lapse/2'
quiet lab exec 'pkill -u ana -f "[u]vicorn serve" || true'

stage export_edge.py le-3jer9wbw/the-edge.md
stage edge.py le-3jer9wbw/the-edge.md
block the-edge
on 'python export_edge.py'
on 'python edge.py lapse-v1.onnx'

stage canary.py le-3jer9wbw/rolling-out.md
block rolling-out
on 'python canary.py'
