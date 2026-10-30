#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of mobile-delivery, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine, lesson 1's ~/planner with its package-lock.json,
# and lesson 1's ~/signing with upload.jks and planner-aligned.apk.
# cachekey.ts and ci-sign.sh are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "cachekey" appends a comment to check.ts as "a source change", and
#     installs and removes dayjs 1.11.13 with npm to change the lockfile and
#     put it back.
#   - "cisign" exports UPLOAD_KEYSTORE_B64 and UPLOAD_PASS through RUNENV, as a
#     CI service exports secrets; the Base64 is made from lesson 1's keystore.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block cachekey
put caching.md cachekey.ts $P/cachekey.ts
run $P 'node cachekey.ts package-lock.json'
run $P 'echo "// a source change" >> check.ts && node cachekey.ts package-lock.json'
run $P 'npm install -E dayjs@1.11.13 --silent && node cachekey.ts package-lock.json'
run $P 'npm uninstall dayjs --silent && node cachekey.ts package-lock.json'
LAB as "cd ~/planner && sed -i '\$d' check.ts"

block cisign
put signing-in-the-pipeline.md ci-sign.sh $P/ci-sign.sh
RUNENV='export UPLOAD_PASS=correct-horse-battery-staple UPLOAD_KEYSTORE_B64=$(base64 -w0 ~/signing/upload.jks)'
run $P 'bash ci-sign.sh planner-ci.apk ~/signing/planner-aligned.apk'
RUNENV='export UPLOAD_PASS=correct-horse-battery-staple'
run $P 'bash ci-sign.sh planner-ci.apk ~/signing/planner-aligned.apk'
RUNENV=
LAB as 'rm -f ~/planner/planner-ci.apk ~/planner/planner-ci.apk.idsig'
