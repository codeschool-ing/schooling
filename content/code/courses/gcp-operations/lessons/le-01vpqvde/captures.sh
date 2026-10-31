#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of gcp-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   PYTHON3_DIR=... bash lab.sh student   # once: ~/gcp built from "environment"
#   bash captures.sh
#
# The shop's files (app.py, test_app.py, Dockerfile, cloudbuild.yaml) are taken
# out of the lesson's own fences with from_lesson, so the files the commands
# used are the bytes the student reads.
#
# STAGED: the emulators are started by emulators_up, which runs the two
# `docker run` lines of "environment" as written. The step containers of
# "the-build" are run by hand with docker: that is the lesson's point, and it
# is said there that this is not Cloud Build. The build cache in "cache" is
# emptied with `docker builder prune` to stand for a fresh Cloud Build worker.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
rm -rf shop

emulators_up
student_env

block check
run 'gcloud version'
run 'gcloud storage buckets create gs://planner-dev-check --location=southamerica-east1'
run 'gcloud storage buckets list --format="value(name)"'
run 'gcloud pubsub topics create check'
run 'du -sh ~/.local/google-cloud-sdk ~/gcp/venv'
run "docker image ls --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep -E 'fake-gcs|emulators'"

block no-variables
( unset CLOUDSDK_AUTH_DISABLE_CREDENTIALS CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE; run 'gcloud storage buckets list' )

block port-taken
run 'docker run -d --rm --name gcs2 -p 4443:4443 fsouza/fake-gcs-server:1.52.2 -scheme http -backend memory -public-host localhost:4443'
quiet 'docker rm -f gcs2'

block not-running
quiet 'docker stop gcs'
run 'gcloud storage buckets list'
emulators_up

# ---- the shop's first build, step by step --------------------------------
mkdir -p shop/api
from_lesson "$HERE/the-build.md" shop/api/app.py > shop/api/app.py
from_lesson "$HERE/the-build.md" shop/api/test_app.py > shop/api/test_app.py
from_lesson "$HERE/the-build.md" shop/api/Dockerfile > shop/api/Dockerfile
from_lesson "$HERE/the-build.md" shop/cloudbuild.yaml > shop/cloudbuild.yaml
cd shop || exit 1
block tree
run 'find . -type f | sort'
block step-test
run 'docker run --rm -v "$PWD":/workspace -w /workspace/api mirror.gcr.io/library/python:3.12.16-slim python -m unittest -v'
block step-build
run 'docker build -q -t southamerica-east1-docker.pkg.dev/planner-dev/shop/api:local api'
run 'docker run -d --rm --name api -p 8080:8080 southamerica-east1-docker.pkg.dev/planner-dev/shop/api:local'
sleep 2
run 'curl -s localhost:8080/products; echo'
quiet 'docker rm -f api'

block cache
quiet 'docker builder prune -af'
run "docker build --progress=plain -t shop-api:cold api 2>&1 | grep -E '^#[67] '"
run "docker build --progress=plain -t shop-api:warm api 2>&1 | grep -E '^#[67] '"
emulators_down
