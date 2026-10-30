#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo FAKE_GCS_BIN=FILE bash ../../lab.sh tools   # once, with the network
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS THE LESSON'S. lab.sh built ~ana from the ```sh fences of
# the-lab.md; this script starts where a student is after "Every time you open
# a terminal", with no emulator running, and starts fake-gcs-server with the
# command of the fifth fence, as the student does in the other terminal.
#
# The failures that need a terminal in a different state are made by unsetting
# what the sixth fence set, inside the command, as a new terminal would have it.
#
# The run has no network at all, so the two blocks that try to reach Google
# (`bq`, and `gcloud` with the endpoint override removed) show what a laptop
# with no route to Google shows; the lesson says so beside them.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-rba8jsay"

emu_start gcs || exit 1

block check
run 'gcloud version'
run 'gcloud auth list'
run 'gcloud storage buckets list'
run 'du -sh ~/gcp'

block fail-path
run 'PATH=/usr/bin:/bin; gcloud version'
block fail-nooverride
run 'env -u CLOUDSDK_AUTH_DISABLE_CREDENTIALS gcloud storage buckets list'
block fail-noproject
run 'env -u CLOUDSDK_CORE_PROJECT gcloud storage buckets list'
block fail-noemu
emu_stop gcs
run 'gcloud storage buckets list'
emu_start gcs
block fail-port
run "timeout 10 $(emu_cmd gcs) 2>&1 | tail -3"
