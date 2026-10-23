#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto runs with its checking OFF, as the section asks: with
# INITIAL_NO_AUTH_ACTION_COUNT set, moto 5.2.3 answers every presigned request
# with HTTP 500, so no presigned URL could be shown at all. result.txt is the
# first ```sh fence of "presigned-urls", written as the student writes it.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# The presigned URLs carry X-Amz-Date and a signature, so they differ on every
# run; no sentence of the prose quotes either.
#
# NOT PRODUCED HERE, and said so in the prose: everything about OneDrive,
# SharePoint, Google Drive, Dropbox, Box and iCloud Drive (taken from their
# documentation); AWS's refusal of an expired or altered presigned URL (moto
# serves both); the seven-day limit; revocation by deactivating the signing key;
# the s3:authType and s3:signatureAge conditions of "controls" (moto ignores
# conditions).
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

moto_fresh
trap 'moto_stop; rm -f ~/aws/result.txt' EXIT
bash -e <(sh_fences "$HERE/presigned-urls.md" 1) || exit 1

block bucket
run 'aws s3api create-bucket --bucket clinic-results --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3 cp --no-progress result.txt s3://clinic-results/maria-souza/2026-10-23.txt'

block anonymous
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-results/maria-souza/2026-10-23.txt'

block presign
run 'aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 900'

block use
keep 'url=$(aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 900)'
keep 'curl -s "$url"'

block expired
keep 'url=$(aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 10); sleep 15; curl -s -w " %{http_code}\n" "$url"'
