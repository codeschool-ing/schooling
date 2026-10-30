#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-hv6mpeyk/captures.sh
#
# Every run is in a network namespace with only loopback in it; the
# containers here publish no port, so Docker works from inside it.
#
# What is STAGED rather than typed:
#   - job.py and the Dockerfile are read out of the blocks of the section
#     `jobs-and-tasks`, and the two main.tf files out of
#     `retries-and-timeouts` and `scheduling-a-job`;
#   - the variables CLOUD_RUN_TASK_INDEX, CLOUD_RUN_TASK_COUNT and
#     CLOUD_RUN_TASK_ATTEMPT are set by hand on `docker run`, playing the part
#     Cloud Run plays; the lesson says so where it does it;
#   - `terraform init`, whose output lesson 1 shows, runs quietly, with a
#     provider cache private to this run (TF_PLUGIN_CACHE_DIR).
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

mkdir -p job jobtf scheduletf
from_lesson "$HERE/jobs-and-tasks.md" job/job.py > job/job.py
from_lesson "$HERE/jobs-and-tasks.md" job/Dockerfile > job/Dockerfile
from_lesson "$HERE/retries-and-timeouts.md" jobtf/main.tf > jobtf/main.tf
from_lesson "$HERE/scheduling-a-job.md" scheduletf/main.tf > scheduletf/main.tf
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.tfcache; mkdir -p $TF_PLUGIN_CACHE_DIR'

block build
run 'docker build -q -t invoices:1 job'
run 'docker run --rm invoices:1'

block three
run 'for i in 0 1 2; do docker run --rm -e CLOUD_RUN_TASK_INDEX=$i -e CLOUD_RUN_TASK_COUNT=3 invoices:1; done'

block help
run "gcloud run jobs create --help | grep -E -A3 '^     --(tasks|parallelism|max-retries|task-timeout)='"

block fail
run 'docker run --rm -e CLOUD_RUN_TASK_INDEX=1 -e CLOUD_RUN_TASK_COUNT=3 -e FAIL_TASK=1 invoices:1; echo "exit status $?"'
run 'docker run --rm -e CLOUD_RUN_TASK_INDEX=1 -e CLOUD_RUN_TASK_COUNT=3 -e CLOUD_RUN_TASK_ATTEMPT=1 -e FAIL_TASK=1 invoices:1; echo "exit status $?"'

block plan-job
cd jobtf || exit 1
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|task_count|parallelism|max_retries|timeout|image|^Plan'"
cd .. || exit 1

block plan-schedule
cd scheduletf || exit 1
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|schedule|time_zone|uri|http_method|service_account_email|^Plan'"
