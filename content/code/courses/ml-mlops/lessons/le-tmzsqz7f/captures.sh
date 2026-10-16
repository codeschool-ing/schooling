#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo -E bash ../le-h449zbxt/captures.sh > /dev/null   # lessons 7, 8 and 9 first,
#   sudo -E bash ../le-3jer9wbw/captures.sh > /dev/null   # in order: each continues
#   sudo -E bash ../le-mh87rchm/captures.sh > /dev/null   # the one before it
#   sudo -E bash captures.sh > out.txt
#
# It continues the state lesson 9's captures leave (the Git and DVC project
# with version 2 in the working tree and version 1 as champion, the feature
# store to 28 February, scores.db holding February's nights) and runs the
# lesson in order. Everything it prints is the same on every run except the
# MLflow run id and the commit hashes.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9

quiet lab exec 'pkill -u ana -f "[u]vicorn serve" || true'
NEW="\$(sqlite3 features.db \"SELECT DISTINCT as_of FROM offline WHERE as_of > '2026-02-28'\")"

block four-more-months
on 'python generate.py --until 2026-06-30'
block four-more-months
on 'dvc add -q shop.db && git add shop.db.dvc && git commit -qm "the shop to 30 June 2026" && git log --oneline -n 1'
block four-more-months
on 'python featurestore.py backfill 2026-03-01 2026-06-28'
on "for night in $NEW; do python score_batch.py \$night > /dev/null; done"
on "sqlite3 -column scores.db \"SELECT cutoff, round(avg(p_lapse), 3) AS mean_p FROM lapse_scores WHERE cutoff >= '2026-02-28' GROUP BY cutoff\""
block four-more-months
on "for night in $NEW; do python watch.py \$night > /dev/null && echo \"\$night ok\" || echo \"\$night ALARM\"; done"

stage drift.py le-tmzsqz7f/a-fixed-reference.md
block a-fixed-reference
on 'python drift.py 2026-03-01 2026-04-26 2026-06-28'

block the-card-arrives
on 'python report_card.py 2026-02-28'
on 'python report_card.py 2026-03-29'

stage segments.py le-tmzsqz7f/who-changed.md
block who-changed
on 'python segments.py 2026-03-29 | head -n 8'

block a-challenger
on "printf 'requests.log\n' >> .gitignore && git add .gitignore *.py && git commit -qm \"serving, monitoring and drift\" && git log --oneline -n 1"
block a-challenger
on 'git checkout v1 -- model.py && git diff --stat HEAD'
block a-challenger
on "sed -i 's/2025-08-31/2025-12-28/; s/2025-11-30/2026-03-29/' dvc.yaml && git diff dvc.yaml"
block a-challenger
on 'dvc repro -q'
block a-challenger
on 'git add . && git commit -qm "lapse model v3: retrained on 28 December 2025" && git tag v3 && python log_run.py'

block deciding
on 'python champion.py | head -n 3'
