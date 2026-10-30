#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", and starts fake-gcs-server with the command lesson 1 gives, as
# the student does in the other terminal, so the emulator is empty. The key
# is made by the first ```sh fence of signed-urls.md, make-key.py is read out
# of the fence after its name and sign.py out of the example in the same file,
# so none of them has a second copy here.
#
# THE KEY IS MADE HERE, BY OPENSSL, FOR AN ACCOUNT THAT DOES NOT EXIST. No real
# key of any Google account is used, read or needed. It changes on every run,
# and so does every signature; the prose quotes none of them.
#
# STAGED: fake-gcs-server runs in the background here; the student runs it in
# the foreground in a terminal of its own. The run has no network, so the
# check `gcloud storage sign-url` makes against Google after signing fails the
# way it fails on a laptop with no route to Google; the lesson says so.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
B=quitanda-curated-prod

emu_start gcs || exit 1
bash -e <(fence "$HERE/signed-urls.md" 1) > /dev/null 2>&1 || exit 1
file_fence "$HERE/signed-urls.md" make-key.py > make-key.py || exit 1
example "$HERE/signed-urls.md" sign.py ~/gcp/sign.py || exit 1

block key
run 'python3 make-key.py'
run "python3 -c 'import json; k = json.load(open(\"signer-key.json\")); print(k[\"client_email\"], k[\"private_key\"].splitlines()[0])'"

block signed-setup
run "gcloud storage buckets create gs://$B --location=southamerica-east1"
run "printf 'day,orders,total_cents\n2026-10-29,412,5108840\n' > daily.csv && gcloud storage cp daily.csv gs://$B/reports/daily.csv"
run "python3 sign.py reports/daily.csv 300 | tr '?&' '\n\n' | cut -c1-120"

block signed-use
run "curl -s -w '%{http_code}\n' \"\$(python3 sign.py reports/daily.csv 300)\""
run "curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' \"\$(python3 sign.py reports/daily.csv 300)\""
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: storage.googleapis.com' \"\$(python3 sign.py reports/no-such-report.csv 300)\""

block signed-weak
run "url=\$(python3 sign.py reports/daily.csv 1); sleep 3; curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' \"\$url\""
run "url=\$(python3 sign.py reports/daily.csv 300); curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' \"\${url%?}x\""
run "curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' http://localhost:4443/$B/reports/daily.csv"

block signed-limits
run "python3 sign.py reports/daily.csv 604801 2>&1 | tail -1"
run "gcloud storage sign-url gs://$B/reports/daily.csv --private-key-file=signer-key.json --duration=8d 2>&1 | head -1"
run "gcloud storage sign-url gs://$B/reports/daily.csv --private-key-file=signer-key.json --duration=10m 2>&1 | cut -c1-100 | head -6"

block ubla
run "gcloud storage buckets create gs://quitanda-logs-prod --location=southamerica-east1 --uniform-bucket-level-access"
run "gcloud storage buckets describe gs://quitanda-logs-prod --format=json"
run "gcloud storage buckets get-iam-policy gs://$B"
run "gcloud storage buckets add-iam-policy-binding gs://$B --member=allUsers --role=roles/storage.objectViewer"

block acl
run "printf '203.0.113.7 GET /checkout 200\n' > access.log && gcloud storage cp access.log gs://quitanda-logs-prod/web/access.log"
run "gcloud storage objects update gs://quitanda-logs-prod/web/access.log --add-acl-grant=entity=allUsers,role=READER"
run "gcloud storage objects describe gs://quitanda-logs-prod/web/access.log --format='json(acl)'"

block pap
run "gcloud storage buckets update gs://quitanda-logs-prod --public-access-prevention=enforced 2>&1 | head -1"
run "gcloud storage buckets update gs://quitanda-logs-prod --public-access-prevention"
run "gcloud storage buckets describe gs://quitanda-logs-prod --format='value(public_access_prevention,uniform_bucket_level_access)'"
run "gcloud storage cp access.log gs://quitanda-logs-prod/web/public.log --predefined-acl=publicRead"
run "gcloud storage objects describe gs://quitanda-logs-prod/web/public.log --format='json(acl)'"

block anonymous
run "curl -s -w '%{http_code}\n' http://localhost:4443/storage/v1/b/quitanda-logs-prod/o/web%2Faccess.log?alt=media"
run "curl -s -w '%{http_code}\n' http://localhost:4443/storage/v1/b/$B/o/reports%2Fdaily.csv?alt=media"
